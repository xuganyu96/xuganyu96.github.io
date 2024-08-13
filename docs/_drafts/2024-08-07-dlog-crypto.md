---
layout: post
title:  "Discrete log, Diffie-Hellman, and ElGamal"
date: 2024-08-07 23:50:58 -0400
categories: cryptography
---

In this post we look back on the intractable problem of discrete log and the rich variety of cryptographic constructions that stemmed from it.

# Discrete log and Diffie-Hellman problems
Let $$G$$ be a group of prime order (such as a prime field $$\mathbb{F}_q$$ where $$q > 2$$ is a prime number) and let $$g$$ be a generator of the group ($$g$$ is guaranteed to exist because [all prime numbers have primitive roots](https://arxiv.org/pdf/2205.11694)). The discrete log problem is described as follows:

> Let $$x \stackrel{\$}{\leftarrow} \mathbb{Z}_q$$ be uniformly random, given $$g^x$$, find $$x$$.

It turns out that the complexity of solving this problem is super-polynomial with respect to the size of prime $$q$$. With a 4000-bit prime number, the fastest computer today will some billions of years to compute a random instance of the discrete log problem.

Related to the discrete log problem is the **computational Diffie-Hellman problem (CDH)** and the **decisional Diffie-Hellman problem (DDH)**.

> **Computational Diffie-Hellman problem**: let $$G$$ be a cyclic group of prime order $$q > 2$$ and $$g$$ be a generator. let $$x, y \stackrel{\$}{\leftarrow} \mathbb{Z}_q$$ be uniformly random. Given $$(g, g^x, g^y)$$, find $$g^{xy}$$.

> **Decisional Diffie-Hellman problem**: let $$G$$ be a cyclic group of prime order $$q > 2$$ and $$g$$ be a generator. Let $$x, y, z \stackrel{\$}{\leftarrow} \mathbb{Z}_q$$ be uniformly random. Given $$(g, g^x, g^y)$$, distinguish $$g^{xy}$$ from $$g^z$$

It's easy to see that if discrete log is easy, then CDH and DDH are both hard. However, there is no straightforward proof that "hardness of discrete log implies hardness of CDH or DDH", so they usually need to be stated as explicit assumptions.

# Diffie-Hellman key exchange
The hardness of CDH and DDH problem serves as the security backbone of the Diffie-Hellman key exchange, which is the only supported method of key exchange in TLS 1.3. The key exchange workflow is as follows:

1. Alice and Bob agree on the choice of $$G$$ and $$g$$
1. Alice samples its secret value $$a \stackrel{\$}{\leftarrow}$$ and computes its public value $$g^a$$. Bob likewise samples its secret value $$b \stackrel{\$}{\leftarrow}$$ and computes its public value $$g^b$$.
1. Alice sends Bob its public value. Bob sends Alice its public value.
1. Alice uses its secret value $$a$$ and Bob's public value $$g^b$$ to compute $$g^{ab} \leftarrow (g^b)^a$$. Bob uses its secret value $$b$$ and Alice's public value $$g^a$$ to compute $$g^{ab} \leftarrow (g^a)^b$$.
1. Alice and Bob have derived a shared secret $$g^{ab}$$.

From the adversary's perspective, the adversary is given $$g, g^a, g^b$$. Under the CDH and DDH assumption, the adversary cannot recover $$g^{ab}$$ or infer anything information about $$g^{ab}$$.

# ElGamal cryptosystem
We can extend the Diffie-Hellman key exchange to build a public-key encryption scheme. There are two key insights:

- Alice never needed to use Bob's secret key and can still arrive at the session key
- The session key is indistinguishable from a truly random element, so it can be used as a one-time pad to obscure a chosen element from the group

Each instance of the encryption scheme is parameterized by the chosen group $$G$$ and the generator $$g$$. The routines are as follows:

- $$\texttt{KeyGen}$$:
    1. Sample $$x \stackrel{\$}{\leftarrow} \mathbb{Z}_q$$
    1. Compute $$u \leftarrow g^x$$
    1. The public key is $$\texttt{pk} = u$$, the secret key is $$\texttt{sk} = x$$
- $$\texttt{Encrypt}(\texttt{pk} = u, m \in G)$$:
    1. Sample $$y \stackrel{\$}{\leftarrow} \mathbb{Z}_q$$
    1. Compute $$v \leftarrow g^y$$
    1. Compute $$w \leftarrow u^y$$
    1. The ciphertext is $$c = (v, m \cdot w)$$
- $$\texttt{Decrypt}(\texttt{sk} = x, c = (c_1, c_2))$$:
    1. Compute $$\hat{w} \leftarrow c_1^x$$
    1. Compute $$\hat{m} \leftarrow c_2 \cdot \hat{w}^{-1}$$
    1. Return the decryption $$\hat{m}$$

The IND-CPA security of this encryption scheme is based on the DDH problem, which is stated in the theorem below:

> For every IND-CPA adversary $$A$$ against the ElGamal encryption scheme, there exists a DDH adversary $$B$$ such that:

$$
\texttt{Adv}_\texttt{IND-CPA}(A) = 2 \cdot \texttt{Adv}_\texttt{DDH}(B)
$$

Unfortunately, this scheme is not secure against chosen-ciphertext attacks. This is because ElGamal ciphertext is malleable: an adversary can manipulate the ciphertext in predictable ways, so a decryption oracle will be able to help adversary decrypt ciphertexts for which it could not recover the decryption for without the decryption oracle.

Fortunately, with a tweak of the security assumption, we can build a public-key encryption scheme that is secure against chosen-ciphertext attack. The trick is to use a hybrid encryption scheme where the plaintext and ciphertext are from a symmetric cipher's space, and the public-key encryption scheme is only used to encrypt the symmetric key. We will call this hybrid ElGamal.

Each instance of hybrid ElGamal is parameterized by the chosen group $$G$$ and generator $$g$$, a symmetric cipher $$\mathcal{E} = (E, D)$$ defined over $$(\mathcal{M}, \mathcal{C}, \mathcal{K})$$, and a hash function $$H: G \rightarrow \mathcal{K}$$. The routines are as follows:

**Key generation**: identical to ElGamal. 

**Encryption**: $$\texttt{Enc}(\texttt{pk} = u, m \in \mathcal{M})$$
- Sample $$y \stackrel{\$}{\leftarrow} \mathbb{Z}_q$$
- Compute $$v \leftarrow g^y, w \leftarrow u^y$$
- Compute $$k \leftarrow H(w)$$
- Compute $$c^\prime \leftarrow E_k(m)$$
- Output ciphertext $$c = (v, c^\prime)$$

**Decryption**: $$\texttt{Dec}(\texttt{sk} = x, c = (v, c^\prime))$$
- Compute $$\hat{w} \leftarrow v^x$$
- Compute $$\hat{k} \leftarrow H(\hat{w})$$
- Compute $$\hat{m} \leftarrow D_{\hat{k}}(c^\prime)$$
- Return $$\hat{m}$$ as the decryption

Consider the following attack using a decryption oracle $$\mathcal{O}^\texttt{Dec}$$:
- Sample a random message $$m \stackrel{\$}{\leftarrow} \mathcal{M}$$
- Sample $$y \stackrel{\$}{\leftarrow} \mathbb{Z}_q$$ and compute $$v \leftarrow g^y$$
- For a given $$w \in G$$, compute $$k \leftarrow H(w)$$ and $$c^\prime \leftarrow E_k(m)$$
- Query the decryption oracle with the ciphertext $$(v, c^\prime)$$

If $$w = g^{xy}$$, then $$k \leftarrow H(w)$$ is the correct key, so the decryption oracle should return exactly $$m$$. If $$w$$ is not, then $$k \leftarrow H(w)$$ is a random key, so the decryption oracle will return a random decryption. In other words, depending on whether the decryption's response matches the $$m$$ or not, the adversary can decide whether $$w = g^{xy}$$ or not. **This allows the adversary to solve the DDH problem**.

Fortunately, the ability to solve DDH problem does not help with solving the CDH problem. As long as $$g^{xy}$$ it not fully recovered, the symmetric key used for encrypting $$m$$ remains unpredictable, so the ciphertext remains semantically secure. However, we do need to state an explicit and distinct assumption:

> **Interactive computational Diffie-Hellman problem**: given $$(g, g^x, g^y)$$ and a DDH oracle, compute $$x^{xy}$$.

Finally the security of hybrid ElGamal is stated in the following theorem:

> Under the random oracle model, for every IND-CCA adversary $$A$$ against hybrid ElGamal, there exists an ICDH adversary $$B$$ and an IND-CPA adversary $$C$$ against the symmetric cipher such that:

$$
\texttt{Adv}_\texttt{IND-CCA}(A) \leq \texttt{Adv}_\texttt{ICDH}(B) + \texttt{Adv}_\texttt{IND-CPA}(C)
$$

# Zero-knowledge proof
WIP
