---
layout: post
title: "Redis from scratch: Frame"
date: 2023-04-28
categories: rust
---

Let's write a Redis client from scratch!

The foundation of client-server interaction is the REdis Serialization Protocol (RESP), which defines the data types and how they encode into sequences of bytes. According to the [official docs](https://redis.io/docs/reference/protocol-spec/), there are five main types of data frames:

|type|encoding|notes|
|:--|:--|:--|
|simple string|`+<data><CRLF>`|binary unsafe|
|error|`-<data><CRLF>`|binary unsafe|
|integer|`:<num><CRLF>`|binary unsafe, number must be in range of signed 64-bit integer|
|bulk|`$<nbytes><CRLF><bytes><CRLF>`|binary safe|
|null|`$-1<CRLF>`|A special case of a bulk frame
|array|`*<nelems><CRLF>`|can be nested|

These types can be trivially represented in an enum:

```rust
pub enum Frame {
    Simple(String),
    Error(String),
    Integer(i64),
    Bulk(Bytes),
    Null,
    Array(Vec<Frame>),
}
```

In addition, serialization is trivial, maybe except for serializing `Frame::Array`, which requires some non-trivial recursive calls.

Deserialization on the other hand, is not trivial. The core function for parsing `Frame` from some unknown bytes will be the `parse` function:

```rust
impl Frame {
    pub fn parse(&mut bytes: Bytes) -> Option<Frame> {
        todo!()
    }
}
```

First we need to consume the first byte to determine what kind of frame we are expecting. For that the method `Bytes::get_u8` is used:

```rust
use bytes::{Buf, Bytes};

impl Frame {
    pub fn parse(&mut bytes: Bytes) -> Option<Frame> {
        match bytes.get_u8() {
            b'+' => { todo!() }
            b'-' => { todo!() }
            b':' => { todo!() }
            b'$' => { todo!() }
            b'*' => { todo!() }
            _ => (),
        }
        return None;
    }
}
```

Another procedure common to parsing binary-unsafe types and to extracting the size of binary-safe types is "read until CRLF":

```rust
const CRLF: &str = "\r\n";

impl Frame {
    fn _parse_binary_safe_string(bytes: &mut Bytes) -> Option<String> {
        let mut msg = vec![];

        while bytes.has_remaining() && !bytes.starts_with(CRLF.as_bytes()) {
            msg.push(bytes.get_u8());
        }

        if bytes.has_remaining() {
            // CRLF should be consumed, as well
            bytes.advance(CRLF.as_bytes().len());
            if let Ok(msg) = String::from_utf8(msg) {
                return Some(msg);
            }
        }
        return None;
    }
}
```

Here is the final implementation:

```rust
fn parse(bytes: &mut Bytes) -> Option<Frame> {
    if !bytes.has_remaining() {
        return None;
    }
    match bytes.get_u8() {
        b'+' => {
            if let Some(msg) = Self::_parse_binary_safe_string(bytes) {
                return Some(Frame::Simple(msg));
            }
        }
        b'-' => {
            if let Some(msg) = Self::_parse_binary_safe_string(bytes) {
                return Some(Frame::Error(msg));
            }
        }
        b':' => {
            if let Some(num) = Self::_parse_binary_safe_string(bytes) {
                if let Ok(num) = num.parse::<i64>() {
                    return Some(Frame::Integer(num));
                }
            }
        }
        b'$' => {
            // Check against Null frame
            if bytes.starts_with(b"-1\r\n") {
                return Some(Frame::Null);
            }

            // Read until the first CRLF to parse the number of bytes
            if let Some(nbytes) = Self::_parse_binary_safe_string(bytes) {
                if let Ok(nbytes) = nbytes.parse::<usize>() {
                    // bytes[0..nbytes] should be the content
                    // bytes[nbytes..nbytes+2] should be another CRLF
                    if bytes.remaining() >= nbytes + 2
                        && bytes.slice(nbytes..nbytes + 2).starts_with(CRLF.as_bytes())
                    {
                        let frame = Frame::Bulk(Bytes::from(bytes.slice(0..nbytes)));
                        bytes.advance(nbytes + 2);
                        return Some(frame);
                    }
                }
            }
        }
        b'*' => {
            // Parsing an array: first obtain the number of elements, then
            // fill a Vector with that number of elements
            if let Some(nelems) = Self::_parse_binary_safe_string(bytes) {
                if let Ok(nelems) = nelems.parse::<usize>() {
                    let mut elems = vec![];

                    for _ in 0..nelems {
                        if let Some(frame) = Self::parse(bytes) {
                            elems.push(frame);
                        } else {
                            return None;
                        }
                    }

                    return Some(Frame::Array(elems));
                }
            }
        }
        _ => (),
    }

    return None;
}
```

Here are the test cases:

```rust
#[test]
fn test_simple_string_deserialization() {
    assert_eq!(
        Frame::parse(&mut Bytes::from("+SET\r\n")),
        Some(Frame::Simple("SET".into())),
    );

    assert_eq!(
        Frame::parse(&mut Bytes::from("+SET\r\n+++++")),
        Some(Frame::Simple("SET".into())),
    );

    assert_eq!(Frame::parse(&mut Bytes::from("+SET\r")), None,);

    assert_eq!(
        Frame::parse(&mut Bytes::from("+\r\n")),
        Some(Frame::Simple("".into())),
    );
}

#[test]
fn test_error_deserialization() {
    assert_eq!(
        Frame::parse(&mut Bytes::from("-Key not found\r\n")),
        Some(Frame::Error("Key not found".into())),
    );

    assert_eq!(
        Frame::parse(&mut Bytes::from("-Key not found\r\n-----")),
        Some(Frame::Error("Key not found".into())),
    );

    assert_eq!(Frame::parse(&mut Bytes::from("-Key not found\r")), None,);

    assert_eq!(
        Frame::parse(&mut Bytes::from("-\r\n")),
        Some(Frame::Error("".into())),
    );
}

#[test]
fn test_integer_deserialization() {
    assert_eq!(
        Frame::parse(&mut Bytes::from(":0\r\n")),
        Some(Frame::Integer(0)),
    );

    assert_eq!(
        Frame::parse(&mut Bytes::from(":1\r\n")),
        Some(Frame::Integer(1)),
    );

    assert_eq!(
        Frame::parse(&mut Bytes::from(":-1\r\n")),
        Some(Frame::Integer(-1)),
    );

    assert_eq!(
        Frame::parse(&mut Bytes::from(":9223372036854775807\r\n")),
        Some(Frame::Integer(9223372036854775807)),
    );

    assert_eq!(
        Frame::parse(&mut Bytes::from(":-9223372036854775808\r\n")),
        Some(Frame::Integer(-9223372036854775808)),
    );

    assert_eq!(
        Frame::parse(&mut Bytes::from(":9223372036854775808\r\n")),
        None,
    );
}

#[test]
fn test_bulk_string_deserialization() {
    // Empty bulk string
    assert_eq!(
        Frame::parse(&mut Bytes::from("$0\r\n\r\n")),
        Some(Frame::Bulk(Bytes::new())),
    );

    // Non-empty bulk string
    assert_eq!(
        Frame::parse(&mut Bytes::from("$36\r\n那么古尔丹，代价是什么呢\r\n")),
        Some(Frame::Bulk(Bytes::from("那么古尔丹，代价是什么呢")))
    );

    // Binary unsafe string
    assert_eq!(
        Frame::parse(&mut Bytes::from(b"$2\r\n\r\n\r\n".to_vec())),
        Some(Frame::Bulk(Bytes::from(b"\r\n".to_vec())))
    );

    // Incomplete
    assert_eq!(Frame::parse(&mut Bytes::from("$10\r\n0123456789")), None);

    // Inconsistent number
    assert_eq!(Frame::parse(&mut Bytes::from("$10\r\n0123456\r\n")), None,);

    // Noise at the end
    assert_eq!(
        Frame::parse(&mut Bytes::from("$10\r\n0123456789\r\nxxxxxx")),
        Some(Frame::Bulk(Bytes::from("0123456789")))
    );
}

#[test]
fn test_null_frame_deserialization() {
    assert_eq!(Frame::parse(&mut Bytes::from("$-1\r\n")), Some(Frame::Null));
}

#[test]
fn test_array_deserialization() {
    assert_eq!(
        Frame::parse(&mut Bytes::from("*0\r\n")),
        Some(Frame::Array(vec![]))
    );

    let some_cmd = Frame::Array(vec![
        Frame::Simple("SET".into()),
        Frame::Bulk(Bytes::from("foo")),
        Frame::Bulk(Bytes::from("bar")),
    ]);
    assert_eq!(Frame::parse(&mut some_cmd.serialize()), Some(some_cmd),);

    let some_cmd = Frame::Array(vec![
        Frame::Simple("DEL".into()),
        Frame::Array(vec![
            Frame::Bulk(Bytes::from("key1")),
            Frame::Bulk(Bytes::from("key2")),
            Frame::Bulk(Bytes::from("key3")),
            Frame::Bulk(Bytes::from("key4")),
        ]),
    ]);
    assert_eq!(Frame::parse(&mut some_cmd.serialize()), Some(some_cmd),);

    assert_eq!(Frame::parse(&mut Bytes::from("*3\r\n:0\r\n:1\r\n")), None);

    assert_eq!(
        Frame::parse(&mut Bytes::from("*2\r\n:0\r\n:1\r\n+++++++")),
        Some(Frame::Array(vec![Frame::Integer(0), Frame::Integer(1)])),
    );
}
```