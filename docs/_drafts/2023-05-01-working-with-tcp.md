---
layout: post
title: "Redis from scratch: working with TCP"
date: 2023-05-01
categories: rust
---

The RESP is built upon TCP, so let's find out how TCP works. TCP is bidirectional, so after the connection is established, there is no meaningful distinction between the client and the server. On the other hand, when establishing a connection, we call the side that initiates the connection the "client" and the other side the "server".

Initiating connection goes as follows:

1. Server listens in on a specific TCP port  
this is necessary because if there is nothing listening in at the TCP port, the client will be refused the connection
2. Client initiates a connection
3. Server acknowledges the client
4. Client acknowledges the server

Step 2 through 4 describes the "triple handshake" that ensures client and server can both reach each other.

Rust's `tokio` crate offers some convenient structs and methods for working with TCP connections. For the remainder of this post we will implement a simple echo server called `tcpecho` which responds to all requests by sending back whatever data is sent by the client.

# Getting started
To make the server configurable, a `clap` Parser struct is defined to gather connection parameters from the command line:

```rust
//! tcpecho: listens in on a Socket and returns any data that clients send
use std::error::Error;
use tokio::net::TcpListener;
use clap::Parser;

/// Listens in on a socket and return any data that the clients send
#[derive(Parser, Debug)]
struct Args {
    /// Set the hostname on which to run the server, defaults to 0.0.0.0
    #[arg(long)]
    host: Option<String>,

    /// The port on which to run the server, defaults to 8000
    #[arg(short, long)]
    port: Option<u64>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();
    let addr = format!("{}:{}", args.host.unwrap_or("0.0.0.0".into()), args.port.unwrap_or(8000));
    let listener = TcpListener::bind(&addr).await?;
    println!("Listening at {addr}");
    let (mut socket, addr) = listener.accept().await?;
    println!("Connected to {:?}", addr);

    return Ok(());
}
```

We can run the server `cargo run --bin tcpecho`. The server will listen in on port `8000` and print the message `"Listening at 0.0.0.0:8000"`, but since no client is connected to the the server, calling `await` on `listener.accept()` will not proceed.

To move server's code forward, we will use netcat `nc` as a client to initiate the connection:

```bash
# TCP port only goes up to 65535
nc -v -p 42069 127.0.0.1 8000
```

The command call returns the message `"Connection to 127.0.0.1 port 8888 [tcp/ddi-tcp-1] succeeded!"`. The server also prints the message

> `Connected to 127.0.0.1:42069`

Note that since TCP is bidirection and the server needs to be able to send message to the client, the client also needs to open a port, but unlike the server which needs to keep a fixed port for the client to initiate the connection to, the client can open any arbitrary port and simply let the server know.

# TCP Socket I/O
At this moment, the server doesn't do anything. As soon as the connection is established, the server exits, and the connection is closed. Let's change this by using the socket to read something from the connection and write it back.

The developers of `tokio` also wrote the `bytes` crate that offers a feature-rich wrapper around byte array `Vec<u8>`, including a cursor for buffered read and write. `bytes::Bytes` dereferences to `Vec<u8>`.

```rust
let mut buf = BufMut::new();
socket.readable().await?
socket.read_buf(&mut buf).await?
socket.writable().await?;
socket.write_buf(&mut buf).await?;
```

We can wrap it in a loop so that the server will keep responding to multiple queries. Note that `socket.read_buf` returns the number of bytes read from the connection, and if the numeber is 0, then the connection is closed, and we should exit the loop:

```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();
    let addr = format!("{}:{}", args.host.unwrap_or("0.0.0.0".into()), args.port.unwrap_or(8000));
    let listener = TcpListener::bind(&addr).await?;
    println!("Listening at {addr}");
    let (mut socket, addr) = listener.accept().await?;
    println!("Connected to {:?}", addr);
    
    loop {
        let mut buf = BytesMut::new();
        socket.readable().await?;
        if let Ok(nbytes) = socket.read_buf(&mut buf).await {
            if nbytes == 0 {
                println!("Client disconnected");
                break;
            }
            println!("{nbytes} bytes read to buffer: '{buf:?}'");
            socket.writable().await?;
            if let Ok(nbytes) = socket.write_buf(&mut buf).await {
                println!("{nbytes} bytes written back");
            }
        }
    }

    return Ok(());
}
```

# Handling multiple clients
The server above can only handle a single client. If we use a second `nc` as a second client, the connection can still be established, but the server will not respond with anything. On a related note, this server's behavior is also not ideal: once the client disconnects, the server will exit, and we will have to restart the server before another client can connect.

First let's explore the behavior of "multiple client connecting":

```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let listener = TcpListener::bind("...").await?;
    let (mut socket, addr1) = listener.accept().await?;
    println!("Connected to {addr1:?}");
    let (mut socket, addr2) = listener.accept().await?;
    println!("Connected to {addr2:?}");
}
```

Then, we will run two instances of `nc` as clients:

```bash
nc -v -p 50000 127.0.0.1 8888  # the first client
nc -v -p 50001 127.0.0.1 8888  # the second client
```

When we run the first client, the first call to `listener.accept()` is unblocked, but the second call to `listener.accept()` is blocked. When we then run the second client, the second call to `listener.accept()` is unblocked.

From the experiment above we've learned that each `accept()` yields a connection to a single client, and from here we can come up with the logic for our long-running, multi-client server logic:

> Repeatedly call `listener.accept()`. Each time it yields, we've connected to a new client, at which time we pass the connection to another thread to then keep calling `read_buf` until it returns 0

```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();
    let addr = format!("{}:{}", args.host.unwrap_or("0.0.0.0".into()), args.port.unwrap_or(8000));
    let listener = TcpListener::bind(&addr).await?;
    println!("Listening at {addr}");

    loop {
        let (socket, addr) = listener.accept().await?;
        println!("Connected to {addr:?}");
        tokio::spawn(async move {
            let _ = echo(socket, addr).await;
        });
    }
}

async fn echo(mut socket: TcpStream, addr: SocketAddr) -> Result<(), Box<dyn Error>> {
    let mut buf = BytesMut::new();

    loop {
        socket.readable().await?;
        let nbytes = socket.read_buf(&mut buf).await?;
        if nbytes == 0 {
            println!("{addr:?} disconnected");
            return Ok(());
        }
        socket.writable().await?;
        socket.write_buf(&mut buf).await?;
    }
}
```