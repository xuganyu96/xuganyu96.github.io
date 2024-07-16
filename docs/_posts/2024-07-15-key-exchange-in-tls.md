---
layout: post
title:  "A review of key exchange protocols in TLS"
date:   2024-07-15 12:48:55 -0400
categories: cryptography
---

# Key exchange algorithms
There are two main categories of key exchange algorithms. The most popular category is Diffie-Hellman key exchange, which is simpler to implement, has smaller attack surfaces, and has great performance. A second category includes using public-key encryption schemes and/or key encapsulation mechanism. Here we give a brief introduction to both categories and give a few examples.

## Diffie-Hellman key exchange
Let $$G$$ be some algebraic group, and $$g$$ be some non-zero element in the group. When two parties need to establish a shared secret, they first agree on the choice of $$G$$ and $$g$$. Then, each sample a random integer $$x, y$$, computes $$g^x, g^y$$, and sends the latter values to each other. The party that generates $$x, g^x$$ will receive $$g^y$$, from which it can compute $$g^{xy} = (g^y)^x$$. The party that generates $$y, g^y$$ will receive $$g^x$$, from which it can also compute $$g^{xy} = (g^x)^y$$.

$$
g^{xy} = \text{X's public key}^\text{Y's secret key} = \text{Y's public key}^\text{X's secret key}
$$

For specific choices of groups and base points, an adversary observing the key exchange will not be able to learn anything about the session key. This idea is expressed in the **computational Diffie-Hellman (CDH) assumption** and the **decisional Diffie-Hellman (DDH) assumption**:

> **Computational Diffie-Hellman assumption**: Given $$g^x, g^y, g$$ where $$x, y$$ are uniformly random, it is computationally difficult to compute $$g^{xy}$$

> **Decision Diffie-Hellman assumption**: Given $$g^x, g^y, g$$ where $$x, y$$ are uniformly random, it is computationally difficult to distinguish $$g^{xy}$$ from $$g^z$$, where $$z$$ is uniformly random

Common choices of algebraic groups for Diffie-Hellman key exchange are prime fields (see [RFC 7919](https://www.rfc-editor.org/rfc/rfc7919.html)) and elliptic curves (see [RFC 7748](https://datatracker.ietf.org/doc/html/rfc7748)).

## Key exchange with a public-key encryption scheme
Another way to perform a key exchange is with a public-key encryption scheme (PKE). When two parties need to establish a common secret, one party would generate a pair of public and secret keys and sends the public key to the other party. The other party generates the shared secret, encrypts it using the received public key, then transmits the ciphertext back. The original sender then uses its secret key to decrypt the ciphertext and obtains the same shared secret.

While a public-key encryption scheme is on paper a viable option, it suffers from several drawbacks compare to a Diffie-Hellman key exchange. First, Diffie-Hellman key exchange only requires two messages, while a PKE key exchange requires three messages. Second, a PKE has a larger attack surface that leaves it more vulnerable to a larger variety of attacks. The version of RSA specified in PKCS#1 v1.5 is famously vulnerable to the [Bleichenbacher attack](https://archiv.infsec.ethz.ch/education/fs08/secsem/bleichenbacher98.pdf), though subsequent revision in PKCS#1 v2 provided an improved version called RSA-OAEP (OAEP is short for "Optimal Asymmetric Encryption Padding"). OAEP was originally proposed by [Bellare et al.](https://link.springer.com/chapter/10.1007/bfb0053428) and later proved to be secure with RSA by [Fujisaki et al.](https://link.springer.com/chapter/10.1007/3-540-44647-8_16).

In implementation, it is also common to use the same keypair across multiple sessions. For example, in TLS 1.2, the server RSA public key used for key exchange comes from the X.509 certificate, which usually remains unchanged for months. Having multiple session keys derived using the same keypair means that if the keypair is compromised in the future, then all these session keys are also compromised. Instead, each session's session key should be established using an independent keypair that is discarded after use. We say this method of using ephemeral keypairs achieves **forward secrecy** meaning that an adversary cannot compromise the secret key and gain access to more than just one session key.

## Key encapsulation mechanism
A key encapsulation mechanism (KEM) is an alternative construction to PKE that is purpose-built to perform key exchange. When two parties need to establish a common secret, one party generates a keypair and sends the public key to the other party. The receiver uses the public key to run the **encapsulation** routine, which returns a ciphertext and a session key. The ciphertext is transmitted back to the key owner, who then uses the secret key to run the **decapsulation** routine, which returns the same session key.

Notice that through out the procedure, there is no mention of any "plaintext" (versus using PKE, where the session key is the plaintext). When modeling the security of a KEM, the fact that the decapsulation routine doesn't return the "decryption" but rather a derived secret means that KEM also has far smaller attack surface than PKEs. In fact, it is well-understood that to build a KEM that achieves the highest level of security (indistinguishability under adaptive chosen ciphertext attack, or *IND-CCA2* for short), one only needs a PKE that achieves the minimum level of security (one-wayness under chosen plaintext attack). The procedure, which is surprisingly simple, is described by [Hofheinz-Hovelmann-Kiltz](https://eprint.iacr.org/2017/604.pdf) and [Daniel J. Bernstein](https://eprint.iacr.org/2018/526).

# Key exchange in TLS 1.2 and 1.3
Key exchange in TLS 1.2 is performed with the following sequence:

1. The client sends `ClientHello` to the server. The `cipher_suites` field in `ClientHello` contains information about the key exchange algorithms that the client supports. There are typically three categories: Diffie-Hellman with long term key (`dh_dss` and `dh_rsa`), ephemeral Diffie-Hellman (`dhe_*`), or RSA (`rsa`)
2. The server processes `ClientHello`, then sends `ServerHello` back to the client. The `cipher_suites` field in `ServerHello` specifies the key exchange algorithm that the server chooses among the cipher suites listed by the client. The choice of key exchange algorithm decides the content of the server certificate and whether the server will send `ServerKeyExchange`
    - **Long-term Diffie-Hellman**: `dh_dss` or `dh_rsa`  
    If the server chooses `dh_dss` or `dh_rsa`, then the server sends `Certificate` but not `ServerKeyExchange`. The server public key contained in `Certificate` is a Diffie-Hellman public key, and the server public key is signed by the certificate authority using either DSS (DSA with finite field) or RSA. After processing `Certificate`, the client sends `ClientKeyExchange`, which contains the client's Diffie-Hellman public key.
    - **RSA**: `rsa`  
    If the server chooses `rsa`, then server sends `Certificate` but not `ServerKeyExchange`. The server public key contained in `Certificate` is an RSA public key. After processing the server certificate, the client uses the server's RSA key to encrypt a randomly generated secret, then sends the secret in the `ClientKeyExchange` message to the server.
    - **Ephemeral Diffie-Hellmann**: `dhe_*`  
    If the server chooses any of the ephemeral Diffie-Hellman key exchange algorithm, then it needs to send both `Certificate` (for authentication only) and `ServerKeyExchange` (for key exchange only). `ServerKeyExchange` contains an ephemeral Diffie-Hellman public key generated by the server. After processing `Certificate` and `ServerKeyExchange`, the client sends `ClientKeyExchange`, which contains an ephemeral Diffie-Hellman public key generated by the client.
3. Client and server compute the shared secret and start encrypted communication

TLS 1.3's key exchange procedure differs from TLS 1.2 in two major aspects:

First, *TLS 1.3 deprecated all key exchanges that use long-term key*. This is because using long-term key for key exchange does not provide **forward secrecy**. If the server's secret key is compromised, then all prior session keys established using server's long-term public key will be compromised. On the other hand, with ephemeral Diffie-Hellman, each session's session key is established with a freshly generated keypair, so compromising one secret key does not give automatic access to other session's secrets. In addition, ephemeral keys are discarded after the shared secret is established (unlike the long-term key in a certificate, which needs to be stored somewhere for a long time), so there is less time for an adversary to compromise the secret key to begin with.

Second, *TLS 1.3 deprecated both `ServerKeyExchange` and `ClientKeyExchange`*. Instead, client sends its key exchange parameters in `ClientHello` using the `key_share` extension (contains the supported DHE groups and the client ephemeral public key), and server sends its response in `ServerHello` using the `key_share` extension (contains the chosen DHE group and the server's ephemeral public key). At the cost of increased communication size for `ClientHello` and `ServerHello`, this implementation saves one round trip when compared to TLS 1.2. In addition, establishing a shared secret as early as `ServerHello` allows all subsequent communication, including all certificate-related messages, to be encrypted, which adds security to the handshake protocol.

To summarize, the key exchange procedure in TLS 1.3 is as follows:

1. Client sends `ClientHello`, in which the `key_share` extension contains client's set of supported Diffie-Hellman groups and the client's ephemeral public keys
2. Server sends `ServerHello`, in which the `key_share` extension contains server's chosen Diffie-Hellman group and the server's ephemeral public key
3. Client and server compute the shared secret and start encrypted communication

# Post-quantum key exchange in TLS
Unfortunately, both finite field and elliptic curve Diffie-Hellman key exchange are vulnerable to quantum computers. In fact, any algebraic group on which Diffie-Hellman works is likely vulnerable to efficient quantum attacks due to its rich and exploitable algebraic structure. In NIST's post-quantum cryptography competition, most submissions proposed key encapsulation mechanisms (KEM) that operate in similar fashion to RSA key exchange. However, sinec TLS 1.3 deprecated `ServerKeyExchange`, integrating post-quantum KEMs into TLS is not a trivial engineering problem.

In 2018 and 2019, Google experimented with implementing hybrid key exchange that integrates post-quantum KEMs into TLS 1.3. The hybrid approach means that the session key is the concatenation of two session keys separately established using classical key exchange algorithms (typically elliptic-curve Diffie-Hellman) and post-quantum algorithms. 

In this a hybrid key exchange, client first generates an ephemeral Diffie-Hellman keypair and an ephemeral post-quantum KEM keypair. The client sends `ClientHello`, in which the `key_share` extension contains the concatenation of the Diffie-Hellman public key and the post-quantum KEM public key. When processing `ClientHello`, the server generates its own ephemeral Diffie-Hellman keypair, then uses the client's public key to run the encapsulation routine, which returns a ciphertext and a shared secret. The server sends `ServerHello`, in which the `key_share` extension contains the server's Diffie-Hellman public key and the ciphertext. The client uses server's Diffie-Hellman public key to derive the Diffie-Hellman session key, and uses its own decapsulation key to derive the KEM session key from the ciphertext. The true session is the concatenation of the Diffie-Hellman session key and the KEM session key.