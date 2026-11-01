from __future__ import annotations
import argparse
import base64
import hashlib
import os
import unittest

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
SYMKEY_BITLENGTH = 256
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


class HybridCiphertext:
    VALID_FIELDS = ("encrypted_symkey", "encrypted_data", "nonce")

    def __init__(self, encrypted_symkey: bytes, encrypted_data: bytes, nonce: bytes):
        # TODO: assumed AAD to be the bytes of encrypted_symkey
        self.encrypted_symkey = encrypted_symkey
        self.encrypted_data = encrypted_data
        self.nonce = nonce

    def serialize(self) -> dict[str, str]:
        encrypted_symkey_b64str = base64.b64encode(self.encrypted_symkey).decode()
        encrypted_data_b64str = base64.b64encode(self.encrypted_data).decode()
        nonce_b64str = base64.b64encode(self.nonce).decode()
        return {
            "encrypted_symkey": f"{encrypted_symkey_b64str}",
            "encrypted_data": f"{encrypted_data_b64str}",
            "nonce": f"{nonce_b64str}",
        }

    @staticmethod
    def deserialize(data: dict[str, str]) -> HybridCiphertext:
        """
        :param data: mapping from field name to base64-encoded value
        """
        for key in HybridCiphertext.VALID_FIELDS:
            if key not in data:
                raise KeyError(f"Missing key {key}")
        for key in data.keys():
            if key not in HybridCiphertext.VALID_FIELDS:
                raise KeyError(f"Invalid key {key}")
        return HybridCiphertext(
            base64.b64decode(data["encrypted_symkey"]),
            base64.b64decode(data["encrypted_data"]),
            base64.b64decode(data["nonce"]),
        )


def encrypt_data(data: bytes, pubkey: rsa.RSAPublicKey) -> HybridCiphertext:
    symkey = AESGCM.generate_key(SYMKEY_BITLENGTH)
    cipher = AESGCM(symkey)
    nonce = os.urandom(AESGCM_NONCE_BYTES)
    encrypted_symkey = pubkey.encrypt(symkey, OAEP_PADDING)
    # TODO: an attacker could use a different AES key, encrypt it under the known RSA public key,
    # and use this wrong AES key to compute a different tag on the ciphertext + AAD? This
    # means that encrypted key should be in AAD to be authenticated?
    encrypted_data = cipher.encrypt(nonce, data, encrypted_symkey)

    return HybridCiphertext(encrypted_symkey, encrypted_data, nonce)


def decrypt_data(h_ct: HybridCiphertext, privkey: rsa.RSAPrivateKey) -> bytes:
    symkey = privkey.decrypt(h_ct.encrypted_symkey, OAEP_PADDING)
    cipher = AESGCM(symkey)
    decryption = cipher.decrypt(h_ct.nonce, h_ct.encrypted_data, h_ct.encrypted_symkey)

    return decryption


class TestFileEncryption(unittest.TestCase):
    def test_hybrid_encryption_roundtrip(self):
        plaintext = b" " * 1024
        privkey = rsa.generate_private_key(
            DEFAULT_RSA_PUBLIC_EXPONENT, MINIMUM_RSA_KEY_SIZE
        )
        pubkey = privkey.public_key()
        h_ct = encrypt_data(plaintext, pubkey)
        raw_data = h_ct.serialize()
        h_ct = HybridCiphertext.deserialize(raw_data)
        decryption = decrypt_data(h_ct, privkey)
        self.assertEqual(plaintext, decryption)


def run_unittest(_):
    unittest.main(module="__main__", argv=["foo"], exit=False)


def get_argparser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="RSA File Encryptor",
        description="A collection of tools for file encryption using RSA",
    )
    subparsers = parser.add_subparsers()
    keygen_parser = subparsers.add_parser("rsakeygen")
    sha256sum_parser = subparsers.add_parser("sha256sum")
    encrypt_parser = subparsers.add_parser("encrypt")
    decrypt_parser = subparsers.add_parser("decrypt")
    unittest_parser = subparsers.add_parser("unittest")
    unittest_parser.set_defaults(func=run_unittest)

    return parser


if __name__ == "__main__":
    parser = get_argparser()
    args = parser.parse_args()
    args.func(args)
    # rsa_keygen()
    # sha256sum("./CodingExercise.JPG")
