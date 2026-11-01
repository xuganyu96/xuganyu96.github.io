# Coding assessment

This is the coding assessment submission from Ganyu (Bruce) Xu for Software
Development Engineer, Chip Product Security at AMD.

Requirements:

- [x] Application to generate an RSA key pair, key size = 2048 bits (Standard Java
  library can be used to generate all keys and hashes).
- [x] Application to generate SHA-256 hash of the attached file. No signing is needed.
  Just print hash in HEX encoding to standard output.
- [x] Application that will encrypt and decrypt the file using the RSA key pair
  generated.
- [x] Send us public and private key, along with original and encrypted files so
  we can confirm the contents of the file is the same as the file encrypted.

## Getting started

This project requires [`pyca/cryptography`](https://cryptography.io/en/latest/):

```bash
pip install -r requirements.txt
```

To generate RSA keypair, run the `rsakeygen` command. By default, public key will
be written to `pubkey.pem`, and private key will be written to `privkey.pem`, but
you can use `--pubkey/--privkey` to change output paths.

```bash
python main.py rsakeygen [--pubkey file.pem] [--privkey file.pem]
```

The keypair files follow standard PKCS8 format and can be manually inspected with
OpenSSL:

```bash
openssl pkey -in privkey.pem -text -noout
openssl pkey -pubin -in pubkey.pem -text -noout
```

To compute SHA-256 checksum, run the `sha256sum` command. The output should align
with Linux/MacOS' built-in `sha256sum` command. The SHA-256 checksum of [CodingExercise.JPG](./CodingExercise.JPG)
is `fa1bed1a61ca81be4d6ecbfe3a75523213a5e399b9db9dd74cfd65303d9c3cc4`.


```bash
python main.py sha256sum CodingExercise.JPG
# check against reference implementation
sha256sum CodingExercise.JPG
```

Use the `encrypt` and `decrypt` command to encrypt and decrypt files. You can check
decryption is correct using SHA-256 checksum:

```bash
python main.py encrypt CodingExercise.JPG pubkey.pem ciphertext.txt
python main.py decrypt ciphertext.txt privkey.pem decryption.jpg

python main.py sha256sum CodingExercise.JPG
python main.py sha256sum decryption.jpg
```

Last but not least, the `unittest` command runs some tests:

```bash
python main.py unittest
```

The `artifacts/` subdirectory contains pre-generated public key, private key, ciphertext,
and decryption using the [`artifacts.sh`](./artifacts.sh) script.

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
encrypted_symkey:<base64 string>
encrypted_data:<base64 string>
nonce:<base64 string>
```

## AI Usage Disclosure

All code and documentation are written **without** AI assistance, except:

- I used ChatGPT as a second opinion on the design of hybrid RSA encryption, specifically
  for using encrypted symmetric key for associated data in the AES-256-GCM encryption
  to provide key binding property.
- Proofreading `README.md` for typos
