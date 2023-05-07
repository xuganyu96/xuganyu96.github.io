---
layout: post
title: "Redis from scratch: the server"
date: 2023-05-06
categories: rust
---

For the final post in the series we will revisit some of the topics covered in the Tokio tutorial and write a minimally functional server that we will then use our own sample client program to test against.

For a first draft, we will not worry about concurrency at all. The server will listen in on the specified port, then for each incoming connection, the server program will serve the connection until it drops before it accepts a new connection. This allows us to focus on the basic logic (especially for interacting with `HashMap`):

```rust
use bytes::Bytes;
use redis::{Command, Connection, Frame};
use std::collections::HashMap;
use std::error::Error;
use tokio::net::TcpListener;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let listener = TcpListener::bind("0.0.0.0:6379").await?;
    let mut db: HashMap<Bytes, Bytes> = HashMap::new();
    loop {
        let (socket, addr) = listener.accept().await?;
        let mut connection = Connection::new(socket);

        println!("Connected to {addr:?}");
        loop {
            let frame = connection.read_frame().await?;
            match frame {
                None => {
                    // read_frame returns None iff the socket read 0 bytes,
                    // signifying a closed connection
                    println!("{addr:?} disconnected");
                    break;
                }
                Some(frame) => {
                    let cmd = Command::parse_command(&frame);
                    match cmd {
                        None => {
                            connection
                                .write_frame(&Frame::Error("Illegal command".into()))
                                .await?;
                        }
                        Some(Command::Set { key, val }) => {
                            db.insert(key, val);
                            connection.write_frame(&Frame::Simple("OK".into())).await?;
                        }
                        Some(Command::Get { key }) => match db.get(&key) {
                            None => {
                                connection
                                    .write_frame(&Frame::Error("Key not found".into()))
                                    .await?;
                            }
                            Some(val) => {
                                connection.write_frame(&Frame::Bulk(val.clone())).await?;
                            }
                        },
                        Some(Command::Del { key }) => match db.remove(&key) {
                            None => {
                                connection.write_frame(&Frame::Integer(0)).await?;
                            }
                            Some(_) => {
                                connection.write_frame(&Frame::Integer(1)).await?;
                            }
                        },
                    }
                }
            }
        }
    }
}
```

Now that we have a working server, let's improve it by making handling incoming connection concurrent. We can address concurrently serve clients by splitting the inner event loop into a `tokio::spawn`, but then we run into a second problem: Rust's borrow checker does not allow two mutable references to the same `HashMap` at the same time.

There are many ways to address this problem. The most straight forward way is to put the `HashMap` behind a `Mutex`, then put the mutex behind an `Arc` so that references to the mutex can be copied into concurrent threads.

Here is a naive implementation, although note that this will not compile for reasons explained after the code block:

```rust
async fn process(mut connection: Connection, db: Arc<Mutex<HashMap<Bytes, Bytes>>>) -> MyResult<()> {
    loop {
        let frame = connection.read_frame().await?;
        match frame {
            None => {
                return Ok(());
            }
            Some(frame) => {
                let cmd = Command::parse_command(&frame);
                match cmd {
                    Some(Command::Set { key, val }) => {
                        let mut lock = db.lock().unwrap();
                        lock.insert(key, val);
                        connection.write_frame(&Frame::Simple("OK".into())).await?;
                    }
                    // ... other operations
                }
            }
        }
    }
}
```

This will not compile because `std::sync::MutexGuard` (the type for `lock`) does not implement `Send` and hence cannot be held across `await` since calling `await` on `connection.write_frame` yields control to another thread that does not have the same memory control.

There are two ways to adress this issue, one is to use `tokio::sync::Mutex` instead of `std::sync::Mutex`:

```rust
async fn process(
    mut connection: Connection,
    db: Arc<Mutex<HashMap<Bytes, Bytes>>>,
) -> MyResult<()> {
    loop {
        let frame = connection.read_frame().await?;
        match frame {
            None => {
                return Ok(());
            }
            Some(frame) => {
                let cmd = Command::parse_command(&frame);
                match cmd {
                    Some(Command::Set { key, val }) => {
                        let mut lock = db.lock().await;
                        lock.insert(key, val);
                        connection.write_frame(&Frame::Simple("OK".into())).await?;
                    },
                    // ... other operations ...
                }
            }
        }
    }
}
```

A second way is to wrap the lock in a synchronous block that drops the lock after we are done using the lock.

```rust
struct DB<T, U> {
    db: Mutex<HashMap<T, U>>,
}

impl<T: Eq + Hash, U: Clone> DB<T, U> {
    fn insert(&self, key: T, val: U) -> Option<U> 
    {
        let mut lock = self.db.lock().unwrap();
        return lock.insert(key, val);
    }

    fn get(&self, key: &T) -> Option<U> {
        let lock = self.db.lock().unwrap();
        return lock.get(key).cloned();
    }

    fn remove(&self, key: &T) -> Option<U> {
        let mut lock = self.db.lock().unwrap();
        return lock.remove(&key);
    }

    fn new() -> Self {
        let db = Mutex::new(HashMap::new());
        return Self { db };
    }
}

async fn process(mut connection: Connection, db: Arc<DB<Bytes, Bytes>>) -> MyResult<()> {
    loop {
        let frame = connection.read_frame().await?;
        match frame {
            None => {
                return Ok(());
            }
            Some(frame) => {
                let cmd = Command::parse_command(&frame);
                match cmd {
                    Some(Command::Set { key, val }) => {
                        db.insert(key, val);
                        connection.write_frame(&Frame::Simple("OK".into())).await?;
                    },
                    // ... other operations ...
                }
            }
        }
    }
}
```

In addition, there are more tricks such as sharding that can be applied to this concurrent database, but in the end when writing production-grade code, it is still best-practice to use mature crates.