---
layout: post
title:  "Naive threshold ElGamal"
date:   2026-01-23 13:09:20 -0500
categories: cryptography
---

<embed src="/assets/notes-on-threshold-diffie-hellman.pdf" width="100%" height="375" type="application/pdf">

Let $$(G, g)$$ be cyclic group of prime order $$q$$.

# Shamir Secret Sharing
Let $$\mathbb{F}$$ be a field. We can define a $$(n, t)$$ secret sharing scheme that splits a secret $$\alpha \in \mathbb{F}$$ into $$n$$ shares such that $$t$$ out of $$n$$ shares is sufficient to recover $$\alpha$$, but $$t-1$$ shares do not leak information.

The secret sharing scheme mainly consists of two routines: share and combine.

**`share`**:
1. Input: the secret $$\alpha \in\mathbb{F}$$
1. Sample $$t-1$$ random elements $$\alpha_1, \alpha_2, \ldots, \alpha_{t-1} \leftarrow \mathbb{F}$$, let $$f(x) \leftarrow \alpha_{t-1}x^{t-1} + \ldots + \alpha_{1}x + \alpha$$ be a polynomial in $$\mathbb{F}[x]$$
2. Pick $$n$$ distinct elements $$\sigma_1, \sigma_2, \ldots, \sigma_n \in \mathbb{F}$$ and compute $$f(\sigma_i)$$ for each $$1 \leq i \leq n$$
1. For each party $$1 \leq i \leq n$$, its secret share is $$(\sigma_i, f(\sigma_i))$$

**`combine`**:
1. Let $$T \subseteq \{1, 2, \ldots, n\}$$ be a subset of size $$t$$. The input is $$\{(\sigma_i, f(\sigma_i)) \mid i \in T\}$$
1. Compute the secret polynomial $$\hat{f}(x) = \sum_{i\in T}\left(f(\sigma_i)\prod_{j\in{T/\{i\}}}\frac{x - \sigma_j}{\sigma_i - \sigma_j}\right)$$
1. Compute $$\hat{\alpha} = \hat{f}(0)$$

# ElGamal cryptosystem
Let $$(G, g)$$ be a cyclic group of prime order $$q$$, $$(E, D)$$ be some symmetric cipher with key space $$\mathcal{K}$$, and $$H: \mathcal{B}^\ast\rightarrow\mathcal{K}$$ be some hash function.
The normal non-threshold ElGamal cryptosystem goes as follows:

**`KeyGen`**:
1. Sample $$\alpha \leftarrow \mathbb{Z}_q$$, $$\texttt{sk}\leftarrow\alpha$$ is the secret key
1. Compute $$g^\alpha$$, $$\texttt{pk}\leftarrow g^\alpha$$ is the public key

**`Enc`**:
1. Input: public key $$\texttt{pk}=g^\alpha$$, some message $$m$$
1. Sample $$\beta \leftarrow \mathbb{Z}_q$$, compute $$v \leftarrow g^\beta$$
1. Compute $$w \leftarrow \texttt{pk}^\beta = g^{\alpha\beta}$$
1. Derive the symmetric key $$k\leftarrow H(v, w)$$
1. Encrypt the message using the symmetric cipher $$c^\prime\leftarrow E(k, m)$$
1. Return the ciphertext $$c \leftarrow (v, c^\prime)$$

**`Dec`**:
1. Input: secret key $$\texttt{sk} = \alpha$$, ciphertext $$c = (v, c^\prime)$$
1. Compute $$\hat{w} \leftarrow v^\alpha$$
1. Derive symmetric key $$\hat{k} \leftarrow H(v, \hat{w})$$
1. Return $$\hat{m}\leftarrow D(\hat{k}, c^\prime)$$

Under the random oracle model, if the interactive computational Diffie-Hellman assumption holds (in short, it means that computational Diffie-Hellman problem remains hard even when adversary has access to a Diffie-Hellman triple oracle), and if the symmetric cipher is semantically secure, then this (hybrid) ElGamal cryptosystem is IND-CCA secure.

# Attempt 1: naive threshold ElGamal cryptosystem