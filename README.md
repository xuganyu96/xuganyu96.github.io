# Coding assessment

**Update:** I wrote the coding assessment with [Python](./main.py) first, then
with [Java](./Main.java). Check [Getting started with Java](#getting-started-with-java)
for running the Java program.

This is the coding assessment submission from Ganyu (Bruce) Xu for Software
Development Engineer, Chip Product Security at AMD.

Requirements:

- [x] Application to generate an RSA key pair, key size = 2048 bits (Standard
  Java library can be used to generate all keys and hashes).
- [x] Application to generate SHA-256 hash of the attached file. No signing is
  needed. Just print hash in HEX encoding to standard output.
- [x] Application that will encrypt and decrypt the file using the RSA key pair
  generated.
- [x] Send us public and private key, along with original and encrypted files
so we can confirm the contents of the file is the same as the file encrypted.

## Getting started

This project requires [`pyca/cryptography`](https://cryptography.io/en/latest/):

```bash
pip install -r requirements.txt
```

To generate RSA keypair, run the `rsakeygen` command. By default, public key
will be written to `pubkey.pem`, and private key will be written to
`privkey.pem`, but you can use `--pubkey/--privkey` to change output paths.

```bash
python main.py rsakeygen [--pubkey file.pem] [--privkey file.pem]
```

The keypair files follow standard format: PKCS#8 for private key,
SubjectPublicKeyInfo for public key. They can be manually inspected with
OpenSSL:

```bash
openssl pkey -in privkey.pem -text -noout
openssl pkey -pubin -in pubkey.pem -text -noout
```

To compute SHA-256 checksum, run the `sha256sum` command. The output should
align with Linux/MacOS' built-in `sha256sum` command. The SHA-256 checksum of
[CodingExercise.JPG](./CodingExercise.JPG) is
`fa1bed1a61ca81be4d6ecbfe3a75523213a5e399b9db9dd74cfd65303d9c3cc4`.

```bash
python main.py sha256sum CodingExercise.JPG
# check against reference implementation
sha256sum CodingExercise.JPG
```

Use the `encrypt` and `decrypt` command to encrypt and decrypt files. You can
check decryption is correct using SHA-256 checksum:

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

The `artifacts/` subdirectory contains pre-generated public key, private key,
ciphertext, and decryption using the [`artifacts.sh`](./artifacts.sh) script.

### Getting started with Java

`Main.java` was developed using OpenJDK 25 and requires Java 21.

```bash
# Compile the program
javac Main.java

# Generate RSA key pair
java Main rsakeygen artifacts/privkey.pem artifacts/pubkey.pem

# Inspect key pair with OpenSSL
openssl pkey -pubin -in artifacts/pubkey.pem -text -noout
openssl pkey -in artifacts/privkey.pem -text -noout

# Encrypt the file
java Main encrypt CodingExercise.JPG artifacts/pubkey.pem artifacts/ciphertext.txt

# Decrypt the file
java Main decrypt artifacts/ciphertext.txt artifacts/privkey.pem artifacts/decryption.jpg

# Check decryption matching plaintext
sha256sum CodingExercise.JPG artifacts/decryption.jpg
```

## Design rationale

With OAEP padding, the maximum plaintext length that an RSA keypair can encrypt
can be computed by `maxlen = key_bytes - 2 * hash_bytes - 2`. Using 2048-bit
keys and SHA-256, the RSA keypair cannot encrypt more than 190 bytes of data.
This is confirmed with `pyca/cryptography`'s runtime behavior, which will raise
`ValueError("Encryption failed")`. The commonly accepted strategy is to deploy
hybrid encryption: encrypt bulk data with a randomly generated symmetric key,
then encrypt the symmetric key with RSA.

For symmetric cipher, I chose AES-256-GCM with randomly generated nonce.
AES-256-GCM provides authenticated encryption with associated data (AEAD),
which provides confidentiality over the plaintext and integrity over both the
AES ciphertext and the associated data. This allows the decryptor to detect if
the authenticated ciphertext has been tampered with. I also chose to include
the encrypted AES key for the associated data to provide integrity for the
encrypted AES key, though without other authentication schemes (i.e. digital
signatures and PKI) to establish the identity of the sender, this cannot
prevent man-in-the-middle attacks that replace the original ciphertext with an
entirely new one.

The hybrid ciphertext consists of these parts: the encrypted AES key in the
form of an RSA ciphertext, the AEAD ciphertext (including the authentication
tag), and the AEAD nonce. I chose to encode binary data using base64 encoding
to provide a ciphertext format that is easy to inspect and parse. An encrypted
file would look something like this:

```text
encrypted_symkey:<base64 string>
encrypted_data:<base64 string>
nonce:<base64 string>
```

## AI Usage Disclosure

All code and documentation are written **without** AI assistance, except:

- I used ChatGPT as a second opinion on the design of hybrid RSA encryption,
  specifically for using encrypted symmetric key for associated data in the
  AES-256-GCM encryption to bind wrapped AES key to ciphertext.
- Proofreading `README.md` for typos
- Review submission package and identify implementation bugs and packaging gaps
