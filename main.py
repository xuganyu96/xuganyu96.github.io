import hashlib
import os

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import serialization, hashes

DEFAULT_RSA_PUBLIC_EXPONENT = 65537
MINIMUM_RSA_KEY_SIZE = 2048
OAEP_PADDING = padding.OAEP(
    mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None
)
# AES-GCM supports 128-bit and 192-bit key, too, but the performance gains are negligible
# on desktop platforms. There is no need to trade security.
SYM_KEY_BITLENGTH = 256
AESGCM_NONCE_BYTES = 12


def rsa_keygen(
    public_exponent: int = DEFAULT_RSA_PUBLIC_EXPONENT,
    key_size: int = MINIMUM_RSA_KEY_SIZE,
    password: bytes | None = None,
    privkey_filename: str = "privkey.pem",
    pubkey_filename: str = "pubkey.pem",
):
    """Generate an RSA keypair following the input parameters, then write private
    key and public key to separate PEM file
    """
    privkey = rsa.generate_private_key(
        public_exponent=public_exponent, key_size=key_size
    )
    pubkey = privkey.public_key()
    encryption = (
        serialization.BestAvailableEncryption(password)
        if password
        else serialization.NoEncryption()
    )
    with open(privkey_filename, "wb") as priv_f, open(pubkey_filename, "wb") as pub_f:
        priv_f.write(
            privkey.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=encryption,
            )
        )
        pub_f.write(
            pubkey.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo,
            )
        )


def sha256sum(path: str):
    """Print SHA-256 checksum of the input file to stdout using hexadecimal encoding"""
    hash = hashlib.sha256()
    with open(path, "rb") as f:
        hash.update(f.read())
    digesthex = hash.digest().hex()
    print(digesthex)


if __name__ == "__main__":
    rsa_keygen()
    sha256sum("./CodingExercise.JPG")

    # RSA keypair with 2048 bytes + SHA-256 hashing + OAEP can encrypt at most
    # 190 bytes of data (256 bytes of key - 2 * 32 bytes hashes - 2 bytes)
    longmsg = b" " * 1024

    # keypair
    privkey = rsa.generate_private_key(DEFAULT_RSA_PUBLIC_EXPONENT, MINIMUM_RSA_KEY_SIZE)
    pubkey = privkey.public_key()

    # encryption
    aeskey = AESGCM.generate_key(SYM_KEY_BITLENGTH)
    cipher = AESGCM(aeskey)
    nonce = os.urandom(AESGCM_NONCE_BYTES)
    # TODO: an attacker could use a different AES key, encrypt it under the known RSA public key,
    # and use this wrong AES key to compute a different tag on the ciphertext + AAD? This
    # means that encrypted key should be in AAD to be authenticated?
    encrypted_msg = cipher.encrypt(nonce, longmsg, b"")
    encrypted_aeskey = pubkey.encrypt(aeskey, OAEP_PADDING)

    # decryption: encrypted_key + nonce + ciphertext + AD
    decrypted_aeskey = privkey.decrypt(encrypted_aeskey, OAEP_PADDING)
    cipher = AESGCM(decrypted_aeskey)
    decrypted_msg = cipher.decrypt(nonce, encrypted_msg, b"")

    if decrypted_msg != longmsg:
        print("ERROR: decryption failed")


