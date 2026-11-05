
/**
 * - [ ] Generate RSA keypair
 * - [ ] Hash a file
 * - [ ] Encrypt a file, then decrypt the file
 */

import java.security.KeyPairGenerator;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.security.PrivateKey;
import java.security.KeyPair;
import java.util.Base64;
import java.util.HexFormat;
import java.io.FileWriter;
import java.io.FileInputStream;
import java.io.IOException;

public class Main {
    public static final int MINIMUM_RSA_KEYSIZE = 2048;

    private static void rsaKeyGen(String privKeyPath, String pubKeyPath, int keySize) {
        try {
            KeyPairGenerator keyPairGen = KeyPairGenerator.getInstance("RSA");
            keyPairGen.initialize(keySize);
            KeyPair keyPair = keyPairGen.generateKeyPair();
            PublicKey pubKey = keyPair.getPublic();
            PrivateKey privKey = keyPair.getPrivate();

            Base64.Encoder b64Encoder = Base64.getMimeEncoder();
            String privKeyPEM = b64Encoder.encodeToString(privKey.getEncoded());
            String pubKeyPEM = b64Encoder.encodeToString(pubKey.getEncoded());
            try (FileWriter writer = new FileWriter(privKeyPath)) {
                writer.write("-----BEGIN PRIVATE KEY-----\n");
                writer.write(privKeyPEM + "\n");
                writer.write("-----END PRIVATE KEY-----\n");
            } catch (IOException e) {
                e.printStackTrace();
            }
            try (FileWriter writer = new FileWriter(pubKeyPath)) {
                writer.write("-----BEGIN PUBLIC KEY-----\n");
                writer.write(pubKeyPEM + "\n");
                writer.write("-----END PUBLIC KEY-----\n");
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

    private static void rsaFileEncrypt(String ciphertextPath, String pubKeyPath, String inPath) {

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
