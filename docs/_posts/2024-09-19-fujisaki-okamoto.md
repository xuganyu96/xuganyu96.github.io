---
layout: post
title:  "The Fujisaki-Okamoto transformation (1): the preliminaries"
date: 2024-09-19 20:50:58 -0400
categories: cryptography
---

In August 2024, NIST's post-quantum cryptography competition came to a (tentative) conclusion with the final standardization of three post-quantum cryptographic algorithms. Two of them are digital signatures: ML-DSA came from CRYSTALS-Dilithium, whose security is based on the conjectured hardness of module lattice problems; ML-STH came from SPHINCS+, whose security is based on the conjectured collision resistance of certain hash functions. There is only one key encapsulation mechanism selected: ML-KEM, whose security is primarily based on the conjectured hardness of lattice problems just like ML-DSA, but whose construction also contains an interesting component called the **Fujisaki-Okamoto transformation**. In this series of blog posts, I would like to discuss what it is and how it is incorporated into ML-KEM.

The Fujisaki-Okamoto transformation was first published in a 1999 paper *"Secure integration of asymmetric and symmetric encryption"* by two Japanese cryptographer from NTT labs: Fujisaki Eiichiro and Okamoto Tatsuyaki. In its original formulation, the transformation takes a public-key encryption scheme and a symmetric encryption scheme, then constructs a hybrid public-key encryption scheme with stronger security properties. Since its initial publication, many cryptographers have worked on improving the security argument and/or extending the core techniques to other applications. In 2017, a group of researchers from the Netherland (Hofheinz, Hovelmann, and Kiltz) published the construction that is adopted into ML-KEM in a paper titled *"A modular analysis of Fujisaki-Okamoto transformation"*. The 2017 construction still takes a public-key encryption scheme as input, but constructs a key encapsulation mechanism, which is what NIST's PQC calls for.

# PKE and KEM
Both **public-key encryption scheme (PKE)** and **key encapsulation mechanism (KEM)** are abstractions of cryptographic algorithms. A PKE is defined by three routines:
- $$\texttt{KeyGen}(1^\lambda)$$ takes the security parameter $$1^\lambda$$ as input and generates a keypair $$(\texttt{pk}, \texttt{sk})$$. Key generation is usually randomized: calling the key generation routine twice should produce two distinct results. We denote randomized output using the following notation: $$(\texttt{pk}, \texttt{sk}) \stackrel{\$}{\leftarrow} \texttt{KeyGen}()$$
- $$\texttt{Enc}(\texttt{pk}, m)$$ encrypts the plaintext message $$m$$ under the public key $$\texttt{pk}$$. The encryption routines of many PKE are also randomized. The randomization of an encryption routine can be captured using a coin (in practice this coin functions as a pseudorandom seed), which we will denote using $$r \in \mathcal{R}$$. Where encryption is randomized $$c \stackrel{\$}{\leftarrow} \texttt{Enc}(\texttt{pk}, m)$$, fixing a coin will make it deterministic $$c \leftarrow \texttt{Enc}(\texttt{pk}, m, r)$$.
- $$\texttt{Dec}(\texttt{sk}, c)$$ decrypts the ciphertext $$c$$ using the secret key $$\texttt{sk}$$. Decryption routine is typically deterministic, because a useful PKE must be **correct**: for all possible keypairs $$(\texttt{pk}, \texttt{sk})$$ and plaintexts $$m$$, $$\texttt{Dec}(\texttt{sk}, \texttt{Enc}(\texttt{pk}, m)) = m$$.

KEM is very similar to a PKE, though the function signatures are slightly different:
- $$(\texttt{pk}, \texttt{sk}) \stackrel{\$}{\leftarrow} \texttt{KeyGen}(1^\lambda)$$ generates random keypairs just like in PKE
- The encapsulation routine $$(c, K) \stackrel{\$}{\leftarrow} \texttt{Encap}(\texttt{pk})$$ randomly generates a ciphertext $$c$$ and a shared secret $$K$$
- The decapsulation routine $$K \leftarrow \texttt{Decap}(\texttt{sk}, c)$$ recovers the shared secret from the ciphertext
- The KEM is **correct** if for all possible keypairs, decapsulating the ciphertext always recovers the correct shared secret, which is often expressed in the following form

$$
P\left[K = \texttt{Decap}(\texttt{sk}, c)  \mid (\texttt{pk}, \texttt{sk}) \stackrel{\$}{\leftarrow} \texttt{KeyGen}(); (c, K) \stackrel{\$}{\leftarrow} \texttt{Encap}(\texttt{pk})\right] = 1
$$

The difference between PKE and KEM are only nominal though, since a KEM can be trivially made from a PKE, and a PKE can be made by combining a KEM with some symmetric cipher (also called "data encapsulation mechanism" or DEM).

# Talking about security
In modern cryptography, the security of a PKE/KEM is usually captured in an adversarial game played by two players: the **challenger** tries to use the encryption scheme to hide some information, while the **adversary** tries to break the scheme and retrieve said information. Three common security notions are:
- **One-wayness**: challenger tries to hide a message, and the adversary, knowing the public key and the ciphertext, tries to recover the message
- **Indistinguishability**: challenger tries to hide which of two known messages is chosen. The adversary has access to the public key and the encryption of the chosen message, and tries to find out which message has been chosen

The security definition also depends on the capabilities of the adversary. In public-key cryptography, the base line capability is **chosen-plaintext attack**: since the adversary has access to the public key, it can encrypt any message it chooses under that public key. Putting the goal and the adversary's capability together gives us the complete definition:

**OW-CPA game** for PKE:
1. Challenger generates random keypair $$(\texttt{pk}, \texttt{sk}) \stackrel{\$}{\leftarrow} \texttt{KeyGen}()$$
1. Challenger samples a random plaintext $$m^\ast \stackrel{\$}{\leftarrow} \mathcal{M}$$ and encrypts it $$c^\ast \stackrel{\$}{\leftarrow} \texttt{Enc}(\texttt{pk}, m)$$
1. Given the public key and the ciphertext, the adversary returns a guess $$\hat{m} \leftarrow A(\texttt{pk}, c^\ast)$$

The adversary wins the game if the guess is correct $$\hat{m} = m^\ast$$. The **advantage** of the adversary is the probability that it wins the game.

$$
\texttt{Adv}_\texttt{OW-CPA}(A) = P\left[\hat{m} = m^\ast\right]
$$

The PKE is OW-CPA secure if no efficient (probabilistic polynomial time Turing machine) adversary can win the game with non-negligible advantage (in theoretical computer science, non-negligible is taken asymptotically with respect to the security parameter $$1^\lambda$$; in practice, proposals for encryption scheme usually discusses the time-complexity of the best known attack).

**IND-CPA game** for PKE:
1. Challenger generates random keypair $$(\texttt{pk}, \texttt{sk}) \stackrel{\$}{\leftarrow} \texttt{KeyGen}()$$
1. Given the public key, the adversary chooses a pair of distinct messages $$(m_0, m_1) \stackrel{\$}{\leftarrow} A(\texttt{pk})$$
1. Challenger flips a coin $$b \stackrel{\$}{\leftarrow} \{0, 1\}$$, then encrypts the chosen message $$c^\ast \stackrel{\$}{\leftarrow} \texttt{Enc}(\texttt{pk}, m_b)$$
1. Given the ciphertext, the adversary guesses which message was chosen: $$\hat{b} \leftarrow A(\texttt{pk}, c^\ast)$$

The adversary wins the game if the guess is correct. The **advantage** of the adversary is the probability of winning the game beyond blind guess:

$$
\texttt{Adv}_\texttt{IND-CPA}(A) = \left\vert P\left[\hat{b} = b\right] - \frac{1}{2}\right\vert
$$

Again, a PKE is IND-CPA secure if no efficient adversary can win the game with non-negligible advantage.

OW-CPA/IND-CPA security constitutes a baseline requirement for encryption scheme, but in the real world we typically require more. The currently accepted security definition needed before an encryption scheme can be widely deployed is called indistinguishability under chosen ciphertext attack (**IND-CCA2**). The security game is largely the same as in IND-CPA, but the adversary has access to a **decryption oracle** $$\mathcal{O}^\texttt{Dec}$$:
- $$\mathcal{O}^\texttt{Dec}: c \mapsto \texttt{Dec}(\texttt{sk}, c)$$ answers decryption query by decrypting the input ciphertext
- To prevent trivial adversary win, after the challenge ciphertext has been generated, $$\mathcal{O}^\texttt{Dec}$$ will not answer decryption query $$c^\ast$$

A KEM's security definition is very similar to a PKE's, although due to the different behavior of its routines, KEM security games are slightly different:
1. Challenger generates keypair $$(\texttt{pk}, \texttt{sk}) \stackrel{\$}{\leftarrow} \texttt{KeyGen}()$$
1. Challenger generates random encapsulation $$(c^\ast, K_0) \stackrel{\$}{\leftarrow} \texttt{Encap}(\texttt{pk})$$
1. Challenger samples a truly random shared secret $$K_1 \stackrel{\$}{\leftarrow} \mathcal{K}$$
1. Challenger flips a coin $$b \stackrel{\$}{\leftarrow} \{0,1\}$$
1. Given $$c^\ast, K_b$$, the adversary guesses whether $$K_b$$ is pseudorandom or truly random: $$\hat{b} \stackrel{\$}{\leftarrow} A(c^\ast, K_b)$$

In the **IND-CCA2** game, the adversary has access to the decapsulation oracle, but the decapsulation oracle will not answer decryption query on the challenge ciphertext.

As a historical footnote, this security definition is called **IND-CCA2** because prior to its formulation, there is an IND-CCA1 security definition, where the adversary can only query the decryption oracle *before* generating the plaintext pair. IND-CCA1 is also called *lunch-time attack*: the attacker can decrypt anything it wants while the victim goes on a lunch break without locking his computer, and the attacker wants to learn about the secrets of the victim after the victim returns, at which point the attacker can no longer access the unlocked computer. Today we don't really use the IND-CCA1 definition anymore. Any time when we say CCA security it by default refers to IND-CCA2.

It turns out, **CCA security is very hard**. Most public-key cryptosystem relies on mathematical constructions that have a lot of structures underneath a ciphertext, so it is not difficult to manipulate the challenge ciphertext, query the decryption oracle on the modified ciphertext, and learn something about the challenge plaintext. PKCS#1 v1.5's RSA encryption scheme is a famous example of a scheme that was thought to be secure and became widely adopted, only to be broken by an adaptive chosen ciphertext attack (the Bleichenbacher attack).

# Arguing about security
Now that we have established what security means, we still need to show that an encryption scheme conforms to said security definition. Contemporary cryptography papers usually formulate the security property of an encryption scheme in the following format:

> For every IND-CPA/IND-CCA2 adversary $$A$$ against the PKE/KEM, there exists another adversary $$B$$ against some underlying hard problem such that the advantage of $$A$$ is bounded by asymptotically by some polynomial of the probability of $$B$$ solving the underlying hard problem

In the proof, we try to construct a hard problem solver $$B$$ that runs the encryption breaker $$A$$ as a sub-routine. Special care must be taken to ensure that the probability distribution of the values fed to $$A$$ must be indistinguishable from the distributions $$A$$ would have gotten when playing a real security game, or $$A$$ will not be able to function as intended.

As a preview to the security proof of the Fujisaki-Okamoto transformation, we are trying to prove: if there exists an IND-CCA2 adversary against the transformed KEM, there exists an IND-CPA adversary against the underyling PKE. In the proof, we need to construct an IND-CPA adversary $$B$$ who can simulate the IND-CCA2 game for the KEM adversary $$A$$. $$A$$ needs the following values to function correctly:
- A public key $$\texttt{pk}$$ obtained from running the key generation routine
- A challenge ciphertext $$c^\ast$$
- A shared secret $$K_b$$ with a $$\frac{1}{2}$$ probability of being pseudorandom (obtained from running encapsulation) and $$\frac{1}{2}$$ probability of being truly random
- A decapsulation oracle

As we will soon see, the public key and the challenge ciphertext are relatively easy to obtain: they are readily available in the IND-CPA game and can be directly used. However, the shared secret and the decapsulation oracle are not easy to simulate, since they both require access to some secret information that the PKE adversary $$B$$ does not have. In fact, we implicitly assumed $$B$$ to be unable to recover the secret key or the challenge plaintext by itself (or $$B$$ won't need $$A$$), so it seems like it is impossible for $$B$$ to simulate the security for $$A$$. The trick here is that $$B$$ does not need to simulate the security game perfectly. It only needs to simulate the game well enough that $$A$$ would have functioned just fine. Here "well enough" means that the probability distribution in the simulated game needs to be statistically close to the probability distribution in the real security game. The difference should be asymptotically negligible with respect to the security parameter.

The notion that $$B$$ only needs to simulate a "close enough" security game for $$A$$ to work its magic is captured in a paper titled "*Sequences of games: a tool for taming complexity in security proofs.*" by NYU math professor Victor Shoup. The technique described in this paper serves as the foundation of many cryptography proofs today. One particularly notable result from this paper is called the **Difference Lemma**, which states:

> Let $$A, B, F$$ be probabilistic events. If $$A \land \neg F \leftrightarrow B \land \neg F$$, then $$\left\vert P\left[A\right] - P\left[B\right]\right\vert \leq P\left[F\right]$$

We refer readers to the original paper for the proof (it's not hard). In a security proof, we often make the following argument:
- $$A$$ is the event that the adversary wins some security game before the modification
- $$B$$ is the event that the adversary wins the same security game after the modification
- $$F$$ is the event that the modification causes the security game to behave differently to the adversary

This way we can argue that even though the game has been modified, the game's behavior will only change with negligible probability, so the adversary will retain its advantage with overwhelming likelihood. From here, we can construct a proof that begins with the standard security game (but that cannot be simulated), make incremental changes that introduce only negligible difference until the game becomes independent from secret information, then construct the second adversary who simulates the final game.

# The Random Oracle Model (ROM)
The concept of random oracle was first introduced in theoretical computer science, then incorporated into the theory of cryptography by Bellare and Rogaway (later the authors of OAEP) in 1993. Within the context of cryptography, random oracle is a way to model a hash function as a stateful probabilistic turing machine. The random oracle answers each unique query with a uniformly random sample from the set of all possible hash values and keeps track of each query-answer pair so that the identical queried will be answered with identical values. Conventionally we denote the oracle by $$\mathcal{O}: q \mapsto h$$, which maintains a query-answer tape $$\mathcal{L}$$. The pseudocode of a hash oracle is as follows:

$$\mathcal{O}(q)$$:
- If there is $$(\tilde{q}, \tilde{h}) \in \mathcal{L}$$ such that $$\tilde{q} = q$$:  
    - `Return` $$\tilde{h}$$
- Else:  
    - Sample a random $$h \stackrel{\$}{\leftarrow} \mathcal{H}$$ from the set of all possible hash values
    - Add $$(q, h)$$ to the tape of query-answer pairs: $$\mathcal{L} \leftarrow \mathcal{L} \cup \{(q, h)\}$$
    - `Return` $$h$$

The random oracle model is a powerful tool in theoretical cryptography because of the existence of the tape. From the querying party's (usually some adversary) point of view, it's impossible to tell "who the random oracle is": it could be a challenger administrating an honest game, but **it could also be another adversary trying to use this adversary to win some other game**, as we will see the the second part of this series. It is important to note that, it is an open problem whether the random oracle model is a realistic assumption of hash functions. On one hand, real-world hash functions clearly do not behave like an oracle, since they are not black boxes, their outputs are pseudorandom at best, not truly random, and they can be evaluated offline. On the other hand, many of today's most widely used primitives, such as RSA-OAEP and many Fiat-Shamir signatures (e.g. EdDSA), all rely on the ROM for their security proofs. The concensus today seemed to be that the ROM provides a convenient theoretical test environment that can be useful when developing a new algorithm, but is insufficient when assessing the real-world security of the scheme.

# Next
> In the next post we will state the transformation and prove its security.