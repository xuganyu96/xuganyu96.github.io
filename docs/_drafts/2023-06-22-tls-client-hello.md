---
layout: post
title:  "TLS v1.3 Client Hello"
date:   2023-05-05 00:00:00
categories: tls-from-scratch
---

Let's send a `ClientHello` first, which should not be difficult as there are very few moving parts.

# Record layer
The outer most layer is a record. Since `ClientHello` is sent before establishing cryptographic parameters, the record will be a TLS Plaintext struct:

```rust
/// Very rough translation of the struct from the spec
struct TLSPlaintext {
    content_type: ContentType,
    legacy_record_version: ProtocolVersion,
    length: u16,
    fragment: Vec<u8>,  // no more than 2^14 bytes
}
```

Among the four fields, we already know what `content_type` and `legacy_record_version` should be:

- `content_type` is set to `ContentType::Handshake` with value `0x16` (1 byte in width)
- `legacy_record_version` is always set to `ProtocolVersion::TLSv1_2`, with value `0x0303` (2 bytes in width)

The value of `length` is the number of bytes of the fragment. Since the content of the client hello is not very large, it's safe to assume that the content of the message itself will not be fragmented.

# Handshake message
The second layer of nesting is the various types of handshake messages, the first a few of which include the `ClientHello`, `HelloRetryRequest`, and `ServerHello`. Each handshake message is structured as follows:

```rust
struct HandshakeMessage {
    msg_type: HandshakeType,
    length: U24,
    payload: HandshakeMessagePayload,
}
```

Among the three fields, we know the value of `msg_type` to be `HandshakeType::ClientHello` (numeric value `0x01` with 1 byte in width). The `length` field will be 3-byte wide, but the specific value will depend on the content of the payload.

# The message payload
The third layer of nesting is the client hello payload itself:

```rust
struct ClientHello {
    legacy_version: ProtocolVersion,
    random: Random,
    legacy_session_id: Vec<u8>,
    cipher_suites: Vec<CipherSuite>,
    legacy_compression_methods: Vec<u8>,
    extensions: Vec<Extension>,
}
```

We know that `legacy_version` is always set to `0x0303`. `random` should be 32 random bytes, for which we will just use the Fibonacci sequence (LOL). `legacy_session_id` can be set to a zero-length vector for TLS 1.3 client. `cipher_suites` is a variable length of pairs of bytes. `legacy_compression_methods` is a list of a single element `0x00`.

Extensions will be a another layer of nesting, but we will discuss them right here since we will only send the very minimal set of extension, namely only `supported_versions`.

Extensions are 