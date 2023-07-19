---
layout: post
title:  "Decomposing a TLS 1.3 ClientHello"
date:   2023-07-18 00:00:00
categories: tls-from-scratch
---

Recently I had the idea to learn more about the TLS protocol, and read up on TLS v1.3's specification. While there is an enormous amount of details that any production implementation needs to pay attention to, for the most fundamental features, the protocol itself it actually not very complex. I was encouraged by the apparent straightforwardness of the protocol and would like to write a toy implementation on my own.

Before delving deep into the implementation, I first used a production-grade TLS library `rustls` to capture the inputs and outputs of a TLS handshake (the source code can be found at the end of this post), and in this post we will deconstruct the first message, which is the `ClientHello`.

The raw bytes, encoded in hexadecimal, are as follows:

```
16030100f3010000ef03030c1968ab2bbd60205f2a40c7f0d492168535d0298c37d998e5eb01e55b61021e20135f1cec7cd5321636bd64411984fd58603bf896d1ef53820869160c6b068a840014130213011303c02cc02bcca9c030c02fcca800ff01000092002b00050403040303000b00020100000a00080006001d00170018000d00140012050304030807080608050804060105010401001700000005000501000000000000001600140000117777772e727573742d6c616e672e6f726700120000003300260024001d0020a04d556163020ff655beeacccf1bbc39c1acdf781551caec45e0e145b7995757002d0002010100230000
```

# The record layer
The first layer of abstraction is the "Record Layer," and since the `ClientHello` is not a protected message, the record layer follows the structure of a `TLSPlaintext`, which roughly looks like the following:

```rust
/// Structure of unprotected messages such as ClientHello, ServerHello, and
/// HelloRetryRequest
struct TLSPlaintext {
    /// A single byte that encodes the type of message, which can be one of:
    /// Invalid: 0x00
    /// ChangeCipherSpec: 0x14
    /// Alert: 0x15
    /// Handshake: 0x16
    /// ApplicationData: 0x17
    content_type: ContentType,

    /// A two-byte wide encoding of the TLS protocol version that this message
    /// follows. For TLS v1.3, this value is either 0x0301 (TLS v1.0) or 0x0303
    /// (TLS v1.2) for backward compatibility reason
    legacy_protocol_version: ProtocolVersion,

    /// Plaintext fragment can contain up to 2^14 bytes. The length value is
    /// encoded with big-endian byte order (also called network byte order,
    /// where the more significant digit is placed at lower-value memory
    /// address)
    length: u16,

    /// The actual content of the message
    fragment: Opaque
}
```

The first a few bytes of the captured `ClientHello` indeed conforms the structure described above, where:

1. first byte is `0x16`, encoding the content type `Handshake`
2. second and third bytes are `0x0301`, encoding the protocol version TLS v1.0
3. third and fourth bytes are `0x00f3`, correctly encoding the length of the content to be 243 bytes

From this we also know that we have correctly captured a complete and valid `ClientHello` and we can safely decompose the content of the record.

# The handshake message
The second layer of abstraction is the handshake message, whose header encodes the handshake message type and the length of the content:

```rust
struct HandshakeMessage {
    /// Each message type is a one-byte encoding of the possible types of
    /// handshake messages, such as ClientHello (0x01), ServerHello (0x02), etc
    msg_type: HandshakeType,

    /// Three-byte encoding of the length of the content
    length: U24,

    /// The content of the handshake message
    payload: Payload
}
```

Of the remaining bytes, the first byte `0x01` encodes the handshake type `ClientHello`, and the next three bytes `0x0000ef` correctly encodes the number of bytes (239) in the remaining content.

# The client hello message
The third layer of abstraction is the `ClientHello` itself, whose structure is as follows:

```rust
struct ClientHello {
    legacy_version: ProtocolVersion,
    random: [u8; 32],
    legacy_session_id: Vec<u8>,
    cipher_suites: Vec<CipherSuite>,
    legacy_compression_methods: Vec<CompressionMethod>,
    extensions: Vec<Extensions>,
}
```

The `ProtocolVersion` is the same as found in the record layer. In the captured message, the protocol version came out to be `0x0303`, which correpsonds to TLS v1.2, again, for compatibility reason. With TLS v1.3, the actual protocol version negotiation is moved to an extension called `supported_versions`, which will be covered at a later section.

The `random` field is a fixed-length vector, meaning that in all possible TLS v1.3 messages that uses this field, the number of bytes that this field takes up is the same. This means that the length of the vector is not encoded in the byte stream, so we simply take the next 32 bytes to be the value of the `random` field.

On the other hand, the remaining four fields (legacy session ID, ciphers suites, compression methods, and extensions) are all **variable-length vectors**, meaning that the number of bytes can vary from message to message and that the length of the vector is encoded in the serialization of the vector itself. We can quickly verify that the remaining message is well formed by checking the length values and make sure that the remaining four fields correctly consume the remainder of the message:

* The maximal length of `session_id` is 32 bytes, so the length value is 1-byte wide. In our message this byte is `0x20`, so we take the next 32 bytes to be the value of the session ID
* The maximal length of `cipher_suites` is $2^{16}-2$ bytes, so the length value is 2-byte wide. In the captured message, the two bytes are `0x0014`, so we take the next 20 bytes
* The maximal length of `legacy_compression_methods` is $2^8-1$ bytes, so the length value is 1-byte wide. In the captured message, this byte is `0x01`, so we take the next byte
* The maximal length of `extensions` is $2^{16}-1$ bytes, so the length value is 2-byte wide. In the captured message, the two bytes are `0x0092`, so we take the next 146 bytes. After taking 146 bytes, we have reached exactly the end of the message, meaning that the message itself is indeed well-formed

For a brief summary before we further dive into individual fields, here are the byte values of each field in the captured `ClientHello`:

```yaml
# ClientHello payload
legacy_protocol: 0x0303
random: 0x0c1968ab2bbd60205f2a40c7f0d492168535d0298c37d998e5eb01e55b61021e
legacy_session_id:
    - 0x20
    - 0x135f1cec7cd5321636bd64411984fd58603bf896d1ef53820869160c6b068a84
cipher_suites:
    - 0x0014
    - 0x130213011303c02cc02bcca9c030c02fcca800ff
legacy_compression_methods:
    - 0x01
    - 0x00
extensions: 
    - 0x0092
    - 0x002b00050403040303000b00020100000a00080006001d00170018000d00140012050304030807080608050804060105010401001700000005000501000000000000001600140000117777772e727573742d6c616e672e6f726700120000003300260024001d0020a04d556163020ff655beeacccf1bbc39c1acdf781551caec45e0e145b7995757002d0002010100230000
```

## Legacy session IDs
Legacy session IDs are a compatibility baggage from pre-TLSv1.3 specificaitons. If the server correctly implements TLS v1.3, then this field should be a zero-length vector, but in the real world there are many sloppy implementations of TLS v1.2 and prior that will misbehave if this field is not filled out, so for compatibility reason it's probably a good idea to generate a new 32-byte session ID.

The session ID should still try to be "random", although it does not need to be cryptographically random.

## Cipher suites
The `cipher_suites` field contains a list of encoded cipher suites, where each cipher suite is encoded with two bytes. From the specification, the following cipher suites can be identified, although there are more cipher suites added beyond the spec, which can be found in the [`rustls` source code](https://github.com/rustls/rustls/blob/3d121b9d6254a4326a9b92a1c40cb002a84f8188/rustls/src/enums.rs#L117):

- `0x1301`: TLS_AES_128_GCM_SHA256
- `0x1302`: TLS_AES_256_GCM_SHA384
- `0x1303`: TLS_CHACHA20_POLY1305_SHA256

## Compression methods
Like legacy session IDs, the compression methods are a compatibility baggage, but unlike legacy session IDs, there is no need to bend backward for bad prior implementations. For TLS v1.3, this field is a list of a single compression method `NULL`, encoded with the value `0x00`.

## Extensions
The `extensions` field is a list of extensions, where each extension is encoded following the tag-length-value structure. Each extension can contain up to `2^{16}-1` bytes of extension data, so the length value is two-byte in width. Each extension type's encoded value can be up to 65535 ($2^{16}$), so each 

We can begin by identifying the tags and lengths without parsing out the values:

|tag|length|value|
|:---|:---|:--|
|002b (supported versions)|0005|0403040303|
|000b|0002|0100|
|000a|0008|0006001d00170018|
|000d|0014|0012050304030807080608050804060105010401|
|0017|0000||
|0005|0005|0100000000|
|0000|0016|00140000117777772e727573742d6c616e672e6f7267|
|0012|0000||
|0033|0026|0024001d0020a04d556163020ff655beeacccf1bbc39c1acdf781551caec45e0e145b7995757|
|002d|0002|0101|
|0023|0000||

Among the extension encodings above, I can recognize the followings from the official spec:

# Appendix
The code I used to capture the outgoing ClientHello encoding (written in Rust, btw):

```rust
use rustls::{OwnedTrustAnchor, RootCertStore};
use std::io::{Read, Write, stdout};
use std::net::TcpStream;
use std::sync::Arc;

struct LoggedTcpStream<T> {
    writer: T,
    socket: TcpStream,
}

impl<T: Write> LoggedTcpStream<T> {
    fn new(writer: T, socket: TcpStream) -> Self {
        return Self { writer, socket };
    }
}

impl<T: Write> Read for LoggedTcpStream<T> {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        let nbytes = self.socket.read(buf)?;
        let hexstr = hex::encode(&buf);
        writeln!(self.writer, "Received: {}", hexstr)?;
        return Ok(nbytes);
    }
}

impl<T: Write> Write for LoggedTcpStream<T> {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        let hexstr = hex::encode(&buf);
        writeln!(self.writer, "Sent: {}", hexstr)?;
        return self.socket.write(&buf);
    }

    fn flush(&mut self) -> std::io::Result<()> {
        self.socket.flush()
    }
}


fn main() {
    let mut root_store = RootCertStore::empty();
    root_store.add_server_trust_anchors(
        webpki_roots::TLS_SERVER_ROOTS
            .0
            .iter()
            .map(|ta| {
                OwnedTrustAnchor::from_subject_spki_name_constraints(
                    ta.subject,
                    ta.spki,
                    ta.name_constraints,
                )
            }),
    );
    let config = rustls::ClientConfig::builder()
        .with_safe_defaults()
        .with_root_certificates(root_store)
        .with_no_client_auth();

    let server_name = "www.rust-lang.org".try_into().unwrap();
    let mut conn = rustls::ClientConnection::new(Arc::new(config), server_name).unwrap();
    let mut sock = LoggedTcpStream::new(
        stdout(),
        TcpStream::connect("www.rust-lang.org:443").unwrap()
    );

    let mut tls = rustls::Stream::new(&mut conn, &mut sock);
    tls.write_all(
        concat!(
            "GET / HTTP/1.1\r\n",
            "Host: www.rust-lang.org\r\n",
            "Connection: close\r\n",
            "Accept-Encoding: identity\r\n",
            "\r\n"
        )
        .as_bytes(),
    )
    .unwrap();
    let ciphersuite = tls
        .conn
        .negotiated_cipher_suite()
        .unwrap();
    writeln!(
        &mut std::io::stderr(),
        "Current ciphersuite: {:?}",
        ciphersuite.suite()
    )
    .unwrap();
    let mut plaintext = Vec::new();
    tls.read_to_end(&mut plaintext).unwrap();
    // stdout().write_all(&plaintext).unwrap();
}
```
