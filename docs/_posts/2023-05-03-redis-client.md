---
layout: post
title: "Redis from scratch: finishing the client"
date: 2023-05-03
categories: rust
---

We are ready to finish the rest of the client library and write a sample program to test it.

For simplicity sake, the client library will support only a small number of the most basic commands and the most basic data types, and without any of the options (such as the `NX` option for `SET`):

- `SET key val` where both key and val are UTF-8 strings
- `GET key` where the key is UTF-8 string
- `DEL key` where the key is UTF-8 string

Hence, we have the top layer abstraction that will be published to the users of the client library:

```rust
pub struct Client {
    // ... the internal state ...
}

impl Client {
    /// For connecting to a Redis server
    pub async fn connect<T: ToSocketAddrs>(addr: T) -> MyResult<Self> { todo!(); }

    /// For sending a SET command and receiving the response
    pub async fn set(&mut self, key: &str, val: &str) -> MyResult<()> { todo!(); }

    /// For sending a GET command and receiving the response
    pub async fn get(&mut self, key: &str) -> MyResult<Option<Bytes>> { todo!(); }

    /// For sending a DEL command and, well, you know the rest
    pub async fn del(&mut self, key: &str) -> MyResult<Option<i64>> { todo!(); }
}
```

# Connecting to server
When calling `Client::connect`, the client initiates a TCP connection to the address specified by opening a TCP socket that will then be used for reading and writing bytes. For more details regarding using `tokio`'s TCP APIs, see [this post]({% post_url 2023-05-01-working-with-tcp %})

```rust
impl Client {
    /// Connect to the server specified at the input address, or return any
    /// error while attempting the connect
    pub async fn connect<T: ToSocketAddrs>(addr: T) -> MyResult<Self> {
        let socket = TcpStream::connect(addr).await?;

        return Ok(Self {
            connection: Connection::new(socket),
        });
    }
}
```

# Layers of abstraction
Between a Redis command and the raw bytes that are transmitted in the network, two layers of abstraction help make the code more readable: `Connection`, `Frame` and `Command` (there is also `Bytes` for buffered I/O on raw bytes `Vec<u8>` but we will use the ready made crate `bytes::Bytes` so we will discuss that in this post).

## Between frame and socket
`Connection` bridges the gap between `Frame` and the network socket. It wraps around the TCP socket and provides two methods for parsing `Frame` from the socket and for writing `Frame` to the socket.

Writing `Frame` to socket is trivial: serialize the frame to a byte array, then write the entire byte array to the socket. Parsing `Frame` from the socket is a bit more involved, and the logic here largely imitates the implementation in the actual mini-redis [here](https://github.com/tokio-rs/mini-redis/blob/7e2bbe32fdf91a883d88ba7f9280f9d29f86414f/src/connection.rs#L56), which is to keep reading from the socket until either the TCP connection is dropped or a valid frame can be parsed:

```rust
/// A wrapper around a TCP socket (TcpStream) for writing byte stream into
/// Bytes and for parsing Bytes into frames
struct Connection {
    socket: TcpStream,
}

impl Connection {
    /// Instantiate a new connection
    fn new(socket: TcpStream) -> Self {
        return Self { socket };
    }

    /// Read bytes from the TcpStream, then parse it. If there is a valid
    /// Frame in the bytes read, then return it. Else return None.
    async fn read_frame(&mut self) -> Result<Option<Frame>, Box<dyn Error>> {
        let mut buf = BytesMut::with_capacity(4096);

        loop {
            // TODO: unnecessary copy but oh well
            if let Some(frame) = Frame::parse(&mut Bytes::from(buf.to_vec())) {
                return Ok(Some(frame));
            }

            self.socket.readable().await?;
            let nbytes = self.socket.read_buf(&mut buf).await?;
            if nbytes == 0 {
                return Ok(None);
            }
        }
    }

    /// Convert the input frame into bytes, then write into the socket
    async fn write_frame(&mut self, frame: &Frame) -> Result<usize, Box<dyn Error>> {
        self.socket.writable().await?;
        let nbytes = self.socket.write(&frame.serialize()).await?;
        return Ok(nbytes);
    }
}
```

On the other hand, `Frame` is an abstraction over `Bytes` and the details, including how frames serialize into bytes and how frames are parsed from bytes, are discussed in [this post]({% post_url 2023-04-28-redis-frames %}).

## Commands
`Command` is an abstraction over `Frame` to further assist with the readability of the code. The enum defines the possible commands including their arguments, and the various methods translate them to and from raw `Frame`:

```rust
#[derive(Debug, Clone, Eq, PartialEq)]
enum Command {
    Set { key: Bytes, val: Bytes },
    Get { key: Bytes },
    Del { key: Bytes },
}

impl Command {
    /// Create a new Set command
    fn set(key: Bytes, val: Bytes) -> Self {
        return Self::Set { key, val };
    }

    /// Create a new Get command
    fn get(key: Bytes) -> Self {
        return Self::Get { key };
    }

    /// Create a new Pop command
    fn del(key: Bytes) -> Self {
        return Self::Del { key };
    }

    /// Convert a command into the appropriate Frame
    fn to_frame(&self) -> Frame {
        return match self {
            Self::Set { key, val } => Frame::Array(vec![
                Frame::Bulk(Bytes::from("SET")),
                Frame::Bulk(Bytes::copy_from_slice(key)),
                Frame::Bulk(Bytes::copy_from_slice(val)),
            ]),
            Self::Get { key } => Frame::Array(vec![
                Frame::Bulk(Bytes::from("GET")),
                Frame::Bulk(Bytes::copy_from_slice(key)),
            ]),
            Self::Del { key } => Frame::Array(vec![
                Frame::Bulk(Bytes::from("DEL")),
                Frame::Bulk(Bytes::copy_from_slice(key)),
            ]),
        };
    }

    /// Parse a frame back into a command. If the frame does not correspond to
    /// any of the supported commands, return None
    ///
    /// If the frame does not strictly conform to the expected format of the
    /// command, this method will return None. For example, if the input frame
    /// has more than three elements, then it will never be parsed into a SET
    /// command even if the first three elements form a valid SET command.
    fn parse_command(frame: &Frame) -> Option<Self> {
        if let Frame::Array(frames) = frame {
            match frames.get(0) {
                Some(Frame::Bulk(bytes)) if bytes == &Bytes::from("SET") => {
                    if frames.len() != 3 {
                        return None;
                    }
                    // unwrapping is ok because the length is already guaranteed
                    let key = frames.get(1).unwrap();
                    let val = frames.get(2).unwrap();
                    if let Frame::Bulk(key) = key {
                        if let Frame::Bulk(val) = val {
                            return Some(Self::set(
                                Bytes::copy_from_slice(key),
                                Bytes::copy_from_slice(val),
                            ));
                        }
                    }
                    return None;
                }
                Some(Frame::Bulk(bytes)) if bytes == &Bytes::from("GET") => {
                    if frames.len() != 2 {
                        return None;
                    }
                    let key = frames.get(1).unwrap();
                    if let Frame::Bulk(key) = key {
                        return Some(Self::get(Bytes::copy_from_slice(&key)));
                    }
                    return None;
                }
                Some(Frame::Bulk(bytes)) if bytes == &Bytes::from("DEL") => {
                    if frames.len() != 2 {
                        return None;
                    }
                    let key = frames.get(1).unwrap();
                    if let Frame::Bulk(key_bytes) = key {
                        return Some(Self::del(Bytes::copy_from_slice(&key_bytes)));
                    }
                    return None;
                }
                _ => {
                    return None;
                }
            }
        }
        // For now, all commands must be arrays
        return None;
    }
}
```

# A sample program
The client library is now complete (at least within our meager scope of three commands and with no performance requirements to begin with). We can test it by running a Redis server (easily done with containers) and writing a simple program to interface with the server:

```rust
//! the sample program
//! 
//! to test it, first run an instance of Redis server, such as with containers:
//! docker run --rm -p 6379:6379 redis:latest
use crate::Client;

#[tokio::main]
async fn main() {
    let mut client = Client::connect("127.0.0.1:6379").await.unwrap();
    client.set("foo", "bar").await.unwrap();
    println!("Set 'foo' to 'bar'");
    println!("Get foo: {:?}", client.get("foo").await.unwrap());
    client.set("foo", "baz").await.unwrap();
    println!("Set 'foo' to 'baz'");
    println!("Get foo: {:?}", client.get("foo").await.unwrap());
    println!("{:?} keys deleted", client.del("foo").await.unwrap());
    println!("Get foo: {:?}", client.get("foo").await.unwrap());
}
```

The program should return the following:

```
Set 'foo' to 'bar'
Get foo: Some(b"bar")
Set 'foo' to 'baz'
Get foo: Some(b"baz")
Some(1) keys deleted
Get foo: None
```