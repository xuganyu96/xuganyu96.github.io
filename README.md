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
openssl pkey -in privkey.pem -text -noout
openssl pkey -pubin -in pubkey.pem -text -noout
```
