import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
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
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.EnumSet;
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
import javax.crypto.spec.SecretKeySpec;

public class Main {

    public static final int MINIMUM_RSA_KEYSIZE = 2048;
    public static final int AES256GCM_KEY_BITS = 256;
    public static final int AES256GCM_TAG_BITS = 128;
    public static final int AES256GCM_NONCE_BYTES = 12;

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
                throw new UncheckedIOException("Failed to write private key", e);
            }
            try (FileWriter writer = new FileWriter(pubKeyPath)) {
                writer.write(derToPem(pubKey.getEncoded(), PemHeaderType.PublicKey));
            } catch (IOException e) {
                throw new UncheckedIOException("Failed to write public key", e);
            }

            Files.setPosixFilePermissions(Path.of(privKeyPath), EnumSet.of(
                    PosixFilePermission.OWNER_READ,
                    PosixFilePermission.OWNER_WRITE));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("RSA not available", e);
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to set permission 600 to " + privKeyPath, e);
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
                throw new UncheckedIOException("Failed to read " + inPath, e);
            }
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(algName + " not available", e);
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

    private static PrivateKey loadRsaPrivateKey(String privKeyPath) {
        try {
            String pem = Files.readString(Path.of(privKeyPath));
            byte der[] = pemToDer(pem, PemHeaderType.PrivateKey);
            PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(der);
            KeyFactory factory = KeyFactory.getInstance("RSA");
            return factory.generatePrivate(keySpec);
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to read RSA private key: " + privKeyPath, e);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("RSA algorithm is unavailable", e);
        } catch (InvalidKeySpecException e) {
            throw new IllegalArgumentException("Invalid RSA private key: " + privKeyPath, e);
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

            byte nonce[] = new byte[AES256GCM_NONCE_BYTES];
            SecureRandom.getInstanceStrong().nextBytes(nonce);
            GCMParameterSpec aesGcmSpec = new GCMParameterSpec(AES256GCM_TAG_BITS, nonce);
            aesGcm.init(Cipher.ENCRYPT_MODE, symKey, aesGcmSpec);
            aesGcm.updateAAD(encryptedSymKey);
            byte encryptedData[] = aesGcm.doFinal(data);

            HybridCiphertext hCt = new HybridCiphertext(encryptedSymKey, encryptedData, nonce);
            return hCt.encodeToString();
        } catch (NoSuchAlgorithmException | NoSuchPaddingException | InvalidAlgorithmParameterException
                | InvalidKeyException | BadPaddingException | IllegalBlockSizeException e) {
            throw new IllegalStateException("Crypto configuration error", e);
        }
    }

    private static void rsaFileEncrypt(String ciphertextPath, String pubKeyPath, String inPath) {
        PublicKey pubKey = loadRsaPublicKey(pubKeyPath);
        try {
            byte data[] = Files.readAllBytes(Path.of(inPath));
            String ciphertextString = rsaHybridEncrypt(pubKey, data);
            Files.writeString(Path.of(ciphertextPath), ciphertextString);
        } catch (IOException e) {
            throw new UncheckedIOException("Unexpected IOException", e);
        }
    }

    static class HybridCiphertext {
        public static final String encryptedSymKeyPrefix = "encrypted_symkey:";
        public static final String encryptedDataPrefix = "encrypted_data:";
        public static final String noncePrefix = "nonce:";

        byte[] encryptedSymKey;
        byte[] encryptedData;
        byte[] nonce;

        public HybridCiphertext(byte[] encryptedSymKey,
                byte[] encryptedData,
                byte[] nonce) {
            this.encryptedSymKey = encryptedSymKey;
            this.encryptedData = encryptedData;
            this.nonce = nonce;
        }

        public String encodeToString() {
            String encryptedDataB64String = Base64.getEncoder().encodeToString(this.encryptedData);
            String nonceB64String = Base64.getEncoder().encodeToString(this.nonce);
            String encryptedSymKeyB64String = Base64.getEncoder().encodeToString(this.encryptedSymKey);
            return HybridCiphertext.encryptedSymKeyPrefix + encryptedSymKeyB64String + "\n"
                    + HybridCiphertext.encryptedDataPrefix + encryptedDataB64String + "\n"
                    + HybridCiphertext.noncePrefix + nonceB64String + "\n";
        }

        public static HybridCiphertext decodeFromString(String ciphertextString) {
            String[] lines = ciphertextString.split("\\s+");
            if (lines.length != 3) {
                throw new IllegalArgumentException("Ciphertext string corrupted");
            }
            byte[] encryptedSymKey = null;
            byte[] encryptedData = null;
            byte[] nonce = null;

            for (String line : lines) {
                if (line.startsWith(HybridCiphertext.encryptedSymKeyPrefix)) {
                    encryptedSymKey = Base64.getDecoder().decode(line.split(":")[1]);
                } else if (line.startsWith(HybridCiphertext.encryptedDataPrefix)) {
                    encryptedData = Base64.getDecoder().decode(line.split(":")[1]);
                } else if (line.startsWith(HybridCiphertext.noncePrefix)) {
                    nonce = Base64.getDecoder().decode(line.split(":")[1]);
                } else {
                    throw new IllegalArgumentException("Invalid line " + line);
                }
            }

            if (encryptedSymKey == null || encryptedData == null || nonce == null) {
                throw new IllegalArgumentException("Ciphertext string missing necessary field");
            }
            return new HybridCiphertext(encryptedSymKey, encryptedData, nonce);
        }
    }

    private static byte[] rsaHybridDecrypt(PrivateKey privKey, String ciphertextString) {
        HybridCiphertext hCt = HybridCiphertext.decodeFromString(ciphertextString);

        try {
            Cipher rsaOaep = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            OAEPParameterSpec oaepSpec = new OAEPParameterSpec("SHA-256", "MGF1", MGF1ParameterSpec.SHA256,
                    PSource.PSpecified.DEFAULT);
            rsaOaep.init(Cipher.DECRYPT_MODE, privKey, oaepSpec);
            byte symKeyRaw[] = rsaOaep.doFinal(hCt.encryptedSymKey);

            Cipher aesGcm = Cipher.getInstance("AES/GCM/NoPadding");
            SecretKey symKey = new SecretKeySpec(symKeyRaw, "AES");
            GCMParameterSpec aesGcmSpec = new GCMParameterSpec(AES256GCM_TAG_BITS, hCt.nonce);
            aesGcm.init(Cipher.DECRYPT_MODE, symKey, aesGcmSpec);
            aesGcm.updateAAD(hCt.encryptedSymKey);
            return aesGcm.doFinal(hCt.encryptedData);
        } catch (NoSuchAlgorithmException | NoSuchPaddingException | InvalidAlgorithmParameterException
                | InvalidKeyException | BadPaddingException | IllegalBlockSizeException e) {
            throw new IllegalStateException("Crypto configuration error", e);
        }
    }

    private static void rsaFileDecrypt(String decryptionPath, String privKeyPath, String ciphertextPath) {
        PrivateKey privKey = loadRsaPrivateKey(privKeyPath);
        try {
            String ciphertextString = Files.readString(Path.of(ciphertextPath));
            byte decryption[] = rsaHybridDecrypt(privKey, ciphertextString);
            Files.write(Path.of(decryptionPath), decryption);
        } catch (IOException e) {
            throw new UncheckedIOException("Unexpected IOException", e);
        }
    }

    public static void main(String args[]) {
        if (args.length == 0) {
            System.out.println("Usage: java Main <rsakeygen|sha256sum|encrypt|decrypt>");
            System.exit(1);
        }
        switch (args[0]) {
            case "rsakeygen" -> {
                if (args.length != 3) {
                    System.out.println("Usage: java Main rsakeygen <privkey.pem> <pubkey.pem>");
                    System.exit(1);
                }
                rsaKeyGen(args[1], args[2], MINIMUM_RSA_KEYSIZE);
            }
            case "sha256sum" -> {
                if (args.length != 2) {
                    System.out.println("Usage: java Main sha256sum <input>");
                    System.exit(1);
                }
                fileDigest(args[1], "SHA-256");
            }
            case "encrypt" -> {
                if (args.length != 4) {
                    System.out.println("Usage: java Main encrypt <data> <pubkey> <ciphertext>");
                    System.exit(1);
                }
                String ciphertextPath = args[3];
                String pubKeyPath = args[2];
                String inPath = args[1];
                rsaFileEncrypt(ciphertextPath, pubKeyPath, inPath);
            }
            case "decrypt" -> {
                if (args.length != 4) {
                    System.out.println("Usage: java Main decrypt <ciphertext> <privkey> <decryption>");
                    System.exit(1);
                }
                String ciphertextPath = args[1];
                String privKeyPath = args[2];
                String decryptionPath = args[3];
                rsaFileDecrypt(decryptionPath, privKeyPath, ciphertextPath);
            }
            default -> {
                System.out.println("Invalid command " + args[0]);
                System.exit(1);
            }
        }
    }
}
