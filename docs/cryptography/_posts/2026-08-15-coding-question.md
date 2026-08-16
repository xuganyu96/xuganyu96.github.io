---
layout: post
title: "Sample coding question: buggy SHA-1 implementation"
date: 2026-08-15
category: cryptography
---

The following implementation of SHA-1 is incorrect. Some of the tests failed.
Please read the
[specification](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf)
and try to debug this implementation.

```rust
pub trait IncrementalHash: Clone {
    const OUT_BYTE: usize;

    fn new() -> Self;
    fn init(&mut self);
    fn update(&mut self, buf: &[u8]);
    fn finalize(&mut self, out: &mut [u8]);
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Sha1State {
    hash: [u32; 5],
    block: [u8; 64],
    block_len: usize,
    processed_bits: u64,
}

impl Sha1State {
    const IV: [u32; 5] = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0];

    fn rotl(x: u32, n: u32) -> u32 {
        // rotating by more than 32 positions for a u32 is meaningless
        let n = n & 0x1f;

        (x << n) | (x >> (32 - n))
    }

    fn sha1func(t: usize, x: u32, y: u32, z: u32) -> u32 {
        match t {
            0..20 => (x & y) ^ ((!x) & z),
            20..40 | 60..80 => x ^ y ^ z,
            40..60 => (x & y) ^ (x & z) ^ (y & z),
            _ => unreachable!("SHA-1 schedule only has 80 terms"),
        }
    }

    fn sha1_k(t: usize) -> u32 {
        match t {
            0..20 => 0x5a827999,
            20..40 => 0x6ed9eba1,
            40..60 => 0x8f1bbcdc,
            60..80 => 0xca62c1d6,
            _ => unreachable!("SHA-1 schedule only has 80 terms"),
        }
    }

    fn sha1_compress(hash: &mut [u32], msg_bytes: &[u8; 64]) {
        let mut schedule: [u32; 80] = [0; 80];
        let mut msg_words: [u32; 16] = [0; 16];

        msg_words.iter_mut().enumerate().for_each(|(i, word)| {
            let mut be_bytes = [0u8; 4];
            be_bytes.copy_from_slice(msg_bytes.get((i * 4)..(i * 4 + 4)).unwrap());
            *word = u32::from_be_bytes(be_bytes);
        });

        for t in 0..16 {
            schedule[t] = msg_words[t];
        }
        for t in 16..80 {
            schedule[t] = Self::rotl(
                schedule[t - 3] ^ schedule[t - 8] ^ schedule[t - 14] ^ schedule[t - 16],
                1,
            );
        }
        let mut a: u32 = hash[0];
        let mut b: u32 = hash[1];
        let mut c: u32 = hash[2];
        let mut d: u32 = hash[3];
        let mut e: u32 = hash[4];
        let mut tmp: u32;

        for t in 0..80 {
            tmp = Self::rotl(a, 5)
                .wrapping_add(Self::sha1func(t, b, c, d))
                .wrapping_add(e)
                .wrapping_add(Self::sha1_k(t))
                .wrapping_add(schedule[t]);
            e = d;
            d = c;
            c = Self::rotl(b, 30);
            b = a;
            a = tmp;
        }

        hash[0] = hash[0].wrapping_add(a);
        hash[1] = hash[1].wrapping_add(b);
        hash[2] = hash[2].wrapping_add(c);
        hash[3] = hash[3].wrapping_add(d);
        hash[4] = hash[4].wrapping_add(e);
    }
}

impl IncrementalHash for Sha1State {
    const OUT_BYTE: usize = 20;

    fn new() -> Self {
        Self {
            hash: [0; 5],
            block: [0; 64],
            block_len: 0,
            processed_bits: 0,
        }
    }

    fn init(&mut self) {
        self.processed_bits = 0;
        self.block.fill(0);
        self.block_len = 0;
        self.hash.copy_from_slice(&Self::IV);
    }

    fn update(&mut self, msg: &[u8]) {
        let mut ingested: usize = 0;

        while ingested < msg.len() {
            debug_assert!(self.block_len < self.block.len());
            let copylen = (self.block.len() - self.block_len).min(msg.len() - ingested);
            self.block
                .get_mut(self.block_len..(self.block_len + copylen))
                .unwrap()
                .copy_from_slice(msg.get(ingested..(ingested + copylen)).unwrap());
            self.block_len += copylen;

            if self.block_len == self.block.len() {
                Self::sha1_compress(&mut self.hash, &self.block);
                self.block_len = 0;
            }
            ingested += copylen;
        }

        self.processed_bits += (msg.len() as u64) * 8;
    }

    fn finalize(&mut self, hash: &mut [u8]) {
        debug_assert!(hash.len() == Self::OUT_BYTE);
        let mut pad = [0u8; 64];
        pad[0] = 0b1000_0000;

        let padlen = match self.block_len {
            0..56 => 64 - 8 - self.block_len,
            56 => 8,
            57..64 => 128 - 8 - self.block_len,
            _ => unreachable!("SHA-1 msg block cannot exceed 64 bytes"),
        };

        self.update(pad.get(0..padlen).unwrap());
        self.update(&self.processed_bits.to_be_bytes());

        self.hash.iter().enumerate().for_each(|(i, word)| {
            let bytes = word.to_be_bytes();
            hash.get_mut((4 * i)..(4 * i + 4))
                .unwrap()
                .copy_from_slice(&bytes);
        });
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sha1_sanity() {
        let mut hasher = Sha1State::new();
        let mut out = [0; 20];

        hasher.init();
        hasher.finalize(&mut out);
        assert_eq!(
            &out,
            &[
                0xda, 0x39, 0xa3, 0xee, 0x5e, 0x6b, 0x4b, 0x0d, 0x32, 0x55, 0xbf, 0xef, 0x95, 0x60,
                0x18, 0x90, 0xaf, 0xd8, 0x07, 0x09,
            ],
            "ERROR: SHA-1 of empty string is incorrect",
        );

        hasher.init();
        hasher.update(b"abc");
        hasher.finalize(&mut out);
        assert_eq!(
            &out,
            &[
                0xa9, 0x99, 0x3e, 0x36, 0x47, 0x06, 0x81, 0x6a, 0xba, 0x3e, 0x25, 0x71, 0x78, 0x50,
                0xc2, 0x6c, 0x9c, 0xd0, 0xd8, 0x9d,
            ],
            "ERROR: SHA-1 of \"abc\" is incorrect",
        );

        hasher.init();
        hasher.update(b"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq");
        hasher.finalize(&mut out);
        assert_eq!(
            &out,
            &[
                0x84, 0x98, 0x3e, 0x44, 0x1c, 0x3b, 0xd2, 0x6e, 0xba, 0xae, 0x4a, 0xa1, 0xf9, 0x51,
                0x29, 0xe5, 0xe5, 0x46, 0x70, 0xf1,
            ],
            "ERROR: SHA-1 of \"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq\" is incorrect",
        );
    }
}
```
