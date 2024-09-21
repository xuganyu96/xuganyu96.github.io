---
layout: post
title:  "The Fujisaki-Okamoto transformation"
date: 2024-09-19 20:50:58 -0400
categories: cryptography
---

The Fujisaki-Okamoto transformation is a generic construction that takes as its input a public key encryption scheme (PKE for short) with weak security properties (which we will explain in detail later), and constructs a key encapsulation mechanism (KEM for short) with strong security properties. **Need more introduction**.

# What are the security goals?
The security of an encryption scheme is described by an adversarial game. There are two players in the game: a **challenger** and an **adversary**. The challenger plays the role of an neutral arbitor, while the adversary tries to use information given by the challenger to "break something about the encryption scheme". The specific security definition is decided by what adversary is trying to do and the power of the adversary. Three common security definitions are:

One-wayness under chosen plaintext attack (**OW-CPA**):
1. Challenger generates a keypair $$(\texttt{pk}, \texttt{sk}) \stackrel{\$}{\leftarrow} \texttt{KeyGen}()$$
1. Challenger samples a random plaintext $$m^\ast \leftarrow \mathcal{M}$$, then encrypts it $$c^\ast \leftarrow \texttt{Enc}(\texttt{pk}, m^\ast)$$. $$m^\ast$$ is called the *challenge plaintext*, $$c^\ast$$ is called the *challenge ciphertext*
1. Adversary is given the public key $$\texttt{pk}$$ and the challenge ciphertext $$c^\ast$$ and asked to output a guess at the value of the decryption $$\hat{m} \leftarrow A(\texttt{pk}, c^\ast)$$
1. Adversary wins the game if and only if the guess is correct: $$\hat{m} = m^\ast$$. The **advantage** of the adversary in this game is the probability that its guess is correct.

> $$\texttt{Adv}_\texttt{OW-CPA}(A) = P\left[\hat{m} = m^\ast\right]$$

Indistinguishability under chosen plaintext attack (**IND-CPA**):
1. Challenger generates keypair $$(\texttt{pk}, \texttt{sk}) \stackrel{\$}{\leftarrow} \texttt{KeyGen}()$$
1. Adversary is given the public key and outputs a pair of distinct messages $$(m_0, m_1) \leftarrow A(\texttt{pk})$$
1. Challenger flips a coin $$b \stackrel{\$}{\leftarrow} \{0,1\}$$, then encrypts the corresponding plaintext $$c^\ast \leftarrow \texttt{Enc}(\texttt{pk}, m_b)$$
1. Adversary is given the challenge ciphertext and outputs a guess at which plaintext was chosen: $$\hat{b} \leftarrow A(\texttt{pk}, c^\ast)$$

The adversary wins the game if the guess is correct. The **advantage** of the adversary in this game is the probability of winning the game ***above blind guess***:

> $$\texttt{Adv}_\texttt{IND-CPA}(A) = \left\vert P\left[\hat{b} = b\right] - \frac{1}{2} \right\vert$$

Indistinguishability under (adaptive) chosen ciphertext attack (**IND-CCA2**) starts out identical to IND-CPA, but the adversary also has access to a **decryption oracle**$$\mathcal{O}^\texttt{Dec}$$. The decryption oracle takes a ciphertext and outputs its decryption $$\texttt{Dec}(\texttt{sk}, c) \leftarrow \mathcal{O}^\texttt{Dec}$$. To prevent trivial wins, the decryption oracle will reject decryption query containing the challenge ciphertext after the challenge ciphertext is revealed.

With key encapsulation mechanism, the security game is slightly different because the "encryption" routine no longer accepts a user-specified "plaintext". Instead, in the security game, the adversary tries to distinguish a pseudorandom key (derived from running the encapsulation routine) from a truly random key.

The security of a scheme can thus be quantified by the advantage of the adversary. Using theoretical lingo this means that the advantage of the adversary is asymptotically negligible with respect to some security parameter (think the size of the modulo in RSA). In practice, $$2^{-80}$$ means anything less than nation state will not be able to crack your encryption, though a minimum of $$2^{-128}$$ is typically required.

# How to argue about security?
When reading cryptography papers, especially in the public-key cryptography space, security theorems are almost always stated in the following fashion:

> If there exists a polynomial-time adversary $$A$$ against the encryption scheme, then there exists a polynomial-time adversary $$B$$ against some other problems (using $$A$$ as a sub-routine) such that the advantage of $$A$$ is bounded by the advantage of $$B$$

From this statement it can be naturally reasoned that if there is no efficient adversary $$B$$ who can solve the other problem (e.g. there is no efficient classical algorithm that can solve the computational Diffie-Hellman problem), then there is no efficient adversary $$A$$ who can win the security game with non-negligible advantage. Therefore the encryption scheme is secure.

**But how do we prove this kind of security theorem?** A popular strategy is called "sequence of games", first formalized by NYU professor Victor Shoup in a 2004 paper *"Sequences of games: a tool for taming complexity in security proofs"*. The main idea is to incrementally modify the security game into a version such that $$B$$ can play the role of the challenger in the modified game for $$A$$. We then argue at each incremental modification that adversary $$A$$ cannot distinguish the game before from the game after, unless some event $$E$$ happens. By the difference lemma (see below), we can claim that the advantage of the adversary $$A$$ in the game before cannot defer from the advantage in the game after by more than the probability of the event $$E$$.

> **Difference lemma:** let $$A, B, F$$ be probabilistic events. If $$A \land \neg F \leftrightarrow B \land \neg F$$, then $$\vert P\left[A\right] - P\left[B\right] \vert = P\left[F\right]$$

## Random oracle
One technique for making security argument is called the **random oracle model**, in which we assume each hash function to have certain computational and statistical properties, and is a black box that the adversary cannot look into. More specifically:

1. A random oracle is defined on some finite input space $$X$$ and some finite output space $$Y$$. It accepts an input $$x\in X$$ and returns some output $$y \in Y$$.
1. A random oracle is stateful: throughout its lifetime, it maintains a tape that records past queries $$(\tilde{x}, \tilde{y})$$
1. When the oracle is queried on some input value $$x$$, it checks whether there has been a past query with a matching input. If there is, then the past query output is returned. If not, then an output value $$y \stackrel{\$}{\leftarrow} Y$$ is uniformly randomly sampled, the input-output pair $$(x,y)$$ is added to the tape, and $$y$$ is returned

At the end of the day, the random oracle model is not a realistic reflection of what hash functions actually do: hash functions are not actually uniformly random, they can be evaluated offline, and they can be taken apart. However, it is also tremendously useful (we will make extensive use of random oracles in the security argument of the Fujisaki-Okamoto transformation): many of today's most widely adopted cryptographic algorithms such as RSA-OAEP and any Fiat-Shamir style signature schemes all rely on the random oracle model to prove their security.

# The Fujisaki-Okamoto transformation
The Fujisaki-Okamoto transformation was first published in 1999 in the paper titled *"Secure integration of asymmetric and symmetric encryption schemes"*. In the ensuing years many works followed up on the 1999 construction, and in 2017 a team from the Netherland published *"A modular analysis of the Fujisaki-Okamoto transformation"*, which became the foundation of current-day application. From a high level, the FO transform deploys two techniques:
1. *de-randomization*:  
If the encryption routine is randomized, then it is made deterministic by deriving randomness from the plaintext. Instead of $$c \stackrel{\$}{\leftarrow} \texttt{Enc}(\texttt{pk}, m)$$, we do $$c \leftarrow \texttt{Enc}(\texttt{pk}, m, G(m))$$ where $$G$$ is some hash function.
2. *re-encryption*:  
In the decryption routine, after recovering the plaintext $$m \leftarrow \texttt{Dec}(\texttt{sk}, c)$$, the plaintext is encrypted again (with *de-randomization*) $$\hat{c} \leftarrow \texttt{Enc}(\texttt{pk}, m, G(m))$$. The ciphertext is considered valid if and only if $$c = \hat{c}$$.

Let's think about how the adversary obtains a ciphertext. If the ciphertext is obtained honestly, meaning that the adversary executed the encryption routine, then the random oracle $$\mathcal{O}^G$$ contains a record $$(m, r)$$ where $$m$$ is the input to the encryption routine, and $$r$$ is the pseudorandom coin. If the adversary has never queried $$G$$ with the decryption of the ciphertext $$c$$, then the output of the random oracle is indistinguishable from a truly random coin, which means that the probability that the queried ciphertext is accepted is bounded by the probability of geting the most probable outcome when encrypting some message $$m$$. In other words, we can replace the true decryption oracle with a simulated oracle who answers decryption query as follows:
- Check the tape of the hash oracle $$\mathcal{O}^G$$: is there a query $$(m, r)$$ such that $$c = \texttt{Enc}(\texttt{pk}, m, r)$$:  
    - If yes, return $$m$$
    - If no, reject the ciphertext

Notice that the simulated decryption oracle does not make use of the secret key, meaning that a second adversary who can simulate the hash oracle, and thus has access to the hash oracle's tape, can run the CCA adversary as a subroutine and service the CCA adversary's decryption query using the simulated oracle. The probability that the CCA adversary's view in the modified game is different from its view in the original game is bounded by the probability that it correctly

# Open problems