from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

DEFAULT_RSA_PUBLIC_EXPONENT = 65537
MINIMUM_RSA_KEY_SIZE = 2048


def rsa_keygen(
    public_exponent: int = DEFAULT_RSA_PUBLIC_EXPONENT,
    key_size: int = MINIMUM_RSA_KEY_SIZE,
    privkey_filename: str = "privkey.pem",
    pubkey_filename: str = "pubkey.pem",
):
    privkey = rsa.generate_private_key(
        public_exponent=public_exponent, key_size=key_size
    )
    pubkey = privkey.public_key()
    with open(privkey_filename, "wb") as priv_f, open(pubkey_filename, "wb") as pub_f:
        priv_f.write(
            privkey.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                # TODO: password encryption is possible
                encryption_algorithm=serialization.NoEncryption(),
            )
        )
        pub_f.write(
            pubkey.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo,
            )
        )


if __name__ == "__main__":
    rsa_keygen()
