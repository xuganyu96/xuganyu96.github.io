# Coding assessment

This is the coding assessment submission from Ganyu (Bruce) Xu for Software
Development Engineer, Chip Product Security at AMD.

Requirements:

- [x] Application to generate an RSA key pair, key size = 2048 bits (Standard Java
  library can be used to generate all keys and hashes).
- [x] Application to generate SHA-256 hash of the attached file. No signing is needed.
  Just print hash in HEX encoding to standard output.
- [ ] Application that will encrypt and decrypt the file using the RSA key pair
  generated.
- [ ] Send us public and private key, along with original and encrypted files so
  we can confirm the contents of the file is the same as the file encrypted.

## Getting started

```bash
main.py rsakeygen [--pubkey file.pem] [--privkey file.pem]
main.py sha256sum <file>
main.py encrypt <input> <pubkey.pem> <output>
main.py decrypt <input> <privkey.pem> <output>
main.py tests
```

```bash
openssl pkey -in privkey.pem -text -noout
openssl pkey -pubin -in pubkey.pem -text -noout
```

## Design rationale

With OAEP padding, the maximum plaintext length that an RSA keypair can encrypt can
be computed by `maxlen = key_bytes - 2 * hash_bytes - 2`. Using 2048-bit keys and
SHA-256, the RSA keypair cannot encrypt more than 190 bytes of data. This is confirmed
with `pyca/cryptography`'s runtime behavior, which will raise `ValueError("Encryption failed")`.
The commonly accepted strategy is to deploy hybrid encryption: encrypt bulk data with
a randomly generated symmetric key, then encrypt the symmetric key with RSA.

For symmetric cipher, I chose to AES-GCM with 256-bit key. The nonce will be randomly
generated from `os.urandom`. The associated data field will be left empty. I chose
AES-GCM because it provides both confidentiality and integrity. The latter is especially
important because it allows the decrypting party to detect whether the symmetric ciphertext
has been tempered with in transit.

The symmetric key will be encrypted by RSA public key using OAEP. Because RSA-OAEP
is already known to be IND-CCA secure, the encrypted symmetric key does not need to
be separately authenticated.

The hybrid ciphertext consists of these parts: an RSA ciphertext, symmetric nonce,
symmetric ciphertext, and associated data. I chose to encode all binary data into
strings using Base64 encoding so that it is easy to serialize and deserialize into
files. Working with raw bytes means I need to implement some kind of binary-safe encoding
scheme (e.g. DER), which I find to be a poor use of the limited time. I chose Base64
over hexadecimal because it is more space efficient. An encrypted blob will look like
this:

```text
encryptedkey:<base64>
nonce:<base64-text>
ciphertext:<base64>
```
