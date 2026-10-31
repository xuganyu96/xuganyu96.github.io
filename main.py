import hashlib

from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import serialization, hashes

DEFAULT_RSA_PUBLIC_EXPONENT = 65537
MINIMUM_RSA_KEY_SIZE = 2048
OAEP_PADDING = padding.OAEP(
    mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None
)


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
