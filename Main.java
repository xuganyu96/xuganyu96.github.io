
/**
 * - [ ] Generate RSA keypair
 * - [ ] Hash a file
 * - [ ] Encrypt a file, then decrypt the file
 */

import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.MGF1ParameterSpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.HexFormat;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.KeyGenerator;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;

public class Main {
    public enum PemHeaderType {
        PublicKey, PrivateKey;

        @Override
        public String toString() {
            return switch (this) {
                case PemHeaderType.PublicKey -> "PUBLIC KEY";
                case PemHeaderType.PrivateKey -> "PRIVATE KEY";
            };
        }
    }

    public static final int MINIMUM_RSA_KEYSIZE = 2048;
    public static final int AES256GCM_KEY_BITS = 256;
    public static final int AES256GCM_TAG_BITS = 128;
    public static final int AES256GCM_NONCE_BYTES = 12;

    /**
     * Encode input DER bytes with Base64 encoding, and wrap with PEM header, footer
     */
    private static String derToPem(byte der[], PemHeaderType header) {
        Base64.Encoder b64Encoder = Base64.getMimeEncoder();
        String pemString = b64Encoder.encodeToString(der);
        return "-----BEGIN " + header + "-----\n"
                + pemString + "\n"
                + "-----END " + header + "-----\n";
    }

    /**
     * Strip PEM header and footer, then base64 decode PEM into DER
     */
    private static byte[] pemToDer(String pem, PemHeaderType header) {
        String pemString = pem.replace("-----BEGIN " + header + "-----\n", "")
                .replace("-----END " + header + "-----\n", "")
                .strip();
        Base64.Decoder b64Decoder = Base64.getMimeDecoder();
        return b64Decoder.decode(pemString);
    }

    private static void rsaKeyGen(String privKeyPath, String pubKeyPath, int keySize) {
        try {
            KeyPairGenerator keyPairGen = KeyPairGenerator.getInstance("RSA");
            keyPairGen.initialize(keySize);
            KeyPair keyPair = keyPairGen.generateKeyPair();
            PublicKey pubKey = keyPair.getPublic();
            PrivateKey privKey = keyPair.getPrivate();

            try (FileWriter writer = new FileWriter(privKeyPath)) {
                writer.write(derToPem(privKey.getEncoded(), PemHeaderType.PrivateKey));
            } catch (IOException e) {
                e.printStackTrace();
            }
            try (FileWriter writer = new FileWriter(pubKeyPath)) {
                writer.write(derToPem(pubKey.getEncoded(), PemHeaderType.PublicKey));
            } catch (IOException e) {
                e.printStackTrace();
            }
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
    }

    private static void fileDigest(String inPath, String algName) {
        try {
            MessageDigest digester = MessageDigest.getInstance(algName);
            try (FileInputStream reader = new FileInputStream(inPath)) {
                byte data[] = reader.readAllBytes();
                byte digest[] = digester.digest(data);
                System.out.println(HexFormat.of().formatHex(digest));
            } catch (IOException e) {
                e.printStackTrace();
            }
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
    }

    private static PublicKey loadRsaPublicKey(String pubKeyPath) {
        try {
            String pem = Files.readString(Path.of(pubKeyPath));
            byte der[] = pemToDer(pem, PemHeaderType.PublicKey);
            X509EncodedKeySpec keySpec = new X509EncodedKeySpec(der);
            KeyFactory factory = KeyFactory.getInstance("RSA");
            return factory.generatePublic(keySpec);
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to read RSA public key: " + pubKeyPath, e);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("RSA algorithm is unavailable", e);
        } catch (InvalidKeySpecException e) {
            throw new IllegalArgumentException("Invalid RSA public key: " + pubKeyPath, e);
        }
    }

    private static String rsaHybridEncrypt(PublicKey pubKey, byte data[]) {
        try {
            Cipher aesGcm = Cipher.getInstance("AES/GCM/NoPadding");
            KeyGenerator aesKeyGenerator = KeyGenerator.getInstance("AES");
            aesKeyGenerator.init(AES256GCM_KEY_BITS, SecureRandom.getInstanceStrong());
            SecretKey symKey = aesKeyGenerator.generateKey();

            byte symKeyRaw[] = symKey.getEncoded();
            Cipher rsaOaep = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            OAEPParameterSpec oaepSpec = new OAEPParameterSpec("SHA-256", "MGF1", MGF1ParameterSpec.SHA256,
                    PSource.PSpecified.DEFAULT);
            rsaOaep.init(Cipher.ENCRYPT_MODE, pubKey, oaepSpec);
            byte encryptedSymKey[] = rsaOaep.doFinal(symKeyRaw);
            String encryptedSymKeyB64String = Base64.getEncoder().encodeToString(encryptedSymKey);

            byte nonce[] = new byte[AES256GCM_NONCE_BYTES];
            SecureRandom.getInstanceStrong().nextBytes(nonce);
            String nonceB64String = Base64.getEncoder().encodeToString(nonce);
            GCMParameterSpec spec = new GCMParameterSpec(AES256GCM_TAG_BITS, nonce);
            aesGcm.init(Cipher.ENCRYPT_MODE, symKey, spec);
            aesGcm.updateAAD(encryptedSymKey);
            byte encryptedData[] = aesGcm.doFinal(data);
            String encryptedDataB64String = Base64.getEncoder().encodeToString(encryptedData);

            return "encrypted_symkey:" + encryptedSymKeyB64String + "\n"
                    + "encrypted_data:" + encryptedDataB64String + "\n"
                    + "nonce:" + nonceB64String + "\n";
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("AES-GCM is not available", e);
        } catch (NoSuchPaddingException e) {
            throw new IllegalStateException("AES-GCM-NoPadding is not available", e);
        } catch (InvalidAlgorithmParameterException e) {
            throw new IllegalStateException("AES-256-GCM w/ 128-bit tag is not available", e);
        } catch (InvalidKeyException e) {
            throw new IllegalStateException("AES-256-GCM w/ 128-bit tag is not available", e);
        } catch (BadPaddingException e) {
            throw new IllegalStateException("AES-256-GCM w/ 128-bit tag is not available", e);
        } catch (IllegalBlockSizeException e) {
            throw new IllegalStateException("Unexpected IllegalBlockSizeException", e);
        }
    }

    private static void rsaFileEncrypt(String ciphertextPath, String pubKeyPath, String inPath) {
        PublicKey pubKey = loadRsaPublicKey(pubKeyPath);
        try {
            byte data[] = Files.readAllBytes(Path.of(inPath));
            String ciphertextString = rsaHybridEncrypt(pubKey, data);
            Files.writeString(Path.of(ciphertextPath), ciphertextString);
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to read input file: " + inPath, e);
        }
    }

    private static void rsaFileDecrypt(String decryptionPath, String privKeyPath, String ciphertextPath) {
    }

    public static void main(String args[]) {
        rsaKeyGen(".tmp/privkey.pem", ".tmp/pubkey.pem", MINIMUM_RSA_KEYSIZE);
        fileDigest("CodingExercise.JPG", "SHA-256");
        rsaFileEncrypt(".tmp/ciphertext.txt", ".tmp/pubkey.pem", "CodingExercise.JPG");
        rsaFileDecrypt(".tmp/decryption.jpg", ".tmp/privkey.pem", ".tmp/ciphertext.txt");
    }
}
