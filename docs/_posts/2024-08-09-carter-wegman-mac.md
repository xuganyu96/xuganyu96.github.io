---
layout: post
title:  "The Carter-Wegman MAC"
date: 2024-08-09 20:51:04 -0400
categories: cryptography
---

A **message authentication code** is a cryptographic construction that aims to provide integrity on secure communications. With a MAC, two parties who already share a secret key can make sure that communication comes from the other party who has the same symmetric key. This is achieved by computing a keyed digest that is practically impossible to compute without knowing the secret key.

Constructing a MAC is a well understood task. There are many efficient and provably secure constructions that have stood the test of time. In this post, we will introduce one such variant called the "Carter-Wegman MAC". Both AES-GCM and ChaCha20-Poly1305, the only two authenticated encryption with associated data schemes used in TLS 1.3, use a Carter-Wegman style MAC to authenticate encrypted communications.

# What is a MAC
Formally speaking, a MAC consists of two routines $$\texttt{Sign}, \texttt{Verify}$$ defined over some key space $$\mathcal{K}$$, some message space $$\mathcal{M}$$, and some digest space $$\mathcal{T}$$. $$\texttt{Sign}$$ takes the secret key $$k \in \mathcal{K}$$, the message $$m \in \mathcal{M}$$, and produce a tag $$t \leftarrow \texttt{Sign}(k, m)$$. $$\texttt{Verify}(k, m, t)$$ takes the secret key, some message, some digest, and return whether the digest is accepted or not (usually 1 for accepted and 0 for rejected).

The security of a MAC is expressed in an adversarial game in which the adversary is trying to produce valid message-tag pairs under an unknown key. The commonly accepted security notion is called **existentially unforgeable under chosen-message attack (EUF-CMA)**, where "chosen-message attack" means that the adversary can query a signing oracle $$\mathcal{O}$$ for the tag of any chosen message. Of course, this means that adversary's forgery must be distinct from the message-tag pairs that have already been queried. The adversarial game proceeds as follows:

1. A symmetric key $$k$$ is uniformly sampled from the key space $$\mathcal{K}$$
2. An adversary $$A$$ is given access to the signing oracle
3. $$A$$ outputs a message-tag pair $$(m, t)$$
4. $$A$$ wins the game if $$\texttt{Verify}(k, m, t) = 1$$

# Attempt 1: polynomial hash function
From the definition of MAC it seems that a MAC behaves very much like a hash function, with the main difference between the presence of a secret key as input. Indeed we can build some kind of keyed hash function $$H$$ and try to make a MAC out of $$H$$.

One such keyed hash function is a polynomial hash function $$H_\texttt{poly}$$. $$H_\texttt{poly}$$ works by parsing the message into a tuple of numbers. The tuple is interpreted as the coefficients of a polynomial, then the polynomial is evaluated at some secret point, where the secret point is the secret key. Here is a more formal definition:

1. Each polynomial hash function is parameterized by a finite field $$\mathbb{F}$$ and a maximal message length $$L$$. The key space and digest space are both $$\mathbb{F}$$, and the message is all tuples of elements of $$\mathbb{F}$$ with lengths $$L$$ or less, which we denote by $$\mathcal{M} = \mathbb{F}^{\leq L}$$
1. Given secret key $$k$$ and message $$m = (m_1, m_2, \ldots, m_l)$$ with length $$l$$, the tag is computed by $$t \leftarrow k^l + k^{k-1} \cdot m_1 + \ldots + m_l$$
1. To verify the digest, simply recompute the digest and compare the recomputed digest against the input digest. If the input digest is valid if and only if the two digests are identical

This $$H_\texttt{poly}$$ is indeed a keyed hash function, and it has a very nice property: without knowing anything about the key, no adversary, even unbounded ones (quantum secure!), can find collision. This is because finding a collision $$m_0 \neq m_1 : H_\texttt{poly}(k, m_0) = H_\texttt{poly}(k, m_1)$$ is equivalent to constructing a polynomial for which the unknown and uniformly random key $$k$$ is a root. Since message length is up to $$L$$, both $$H(k, m_0)$$ and $$H(k, m_1)$$ are at most degree-$$L$$ polynomials, so their difference has at most degree-$$L$$. From the fundamental theorem of algebra we know that there are atmost $$L$$ roots for such polynomials, while there are $$\vert \mathbb{F} \vert$$ possible values from which the secret key can be picked. Therefore, the probability that a uniformly random $$k$$ is the root is at most $$\frac{L}{\vert\mathbb{F}\vert}$$.

However, $$H_\texttt{poly}$$ by itself is not enough for a secure MAC. While it has collision resistance against possibly unbounded adversaries, such collision resistance is conditioned on "nothing is revealed about the secret key" (we can call this a zero-time collision resistance, meaning that the adversary obtained no hash values under the unknown secret key). If a single message-tag pair is revealed, an adversary can try to solve the polynomial and recover the secret key, which can be done efficiently and with high probability of success. If chosen message is allowed, then an adversary can simply query a length-1 message $$m = (0)$$, and the corresponding tag is exactly the secret key $$k$$.

# Attempt 2: polynomial hash function + pseudorandom function
The main weakness of using $$H_\texttt{poly}(k, m)$$ by itself as a MAC is that the tag reveals too much information about the secret key. This can be fixed by adding a pseudorandom function, which can be used to further scrample the tag and obscure the information about the tag. We now present attempt 2, which we will call the proto-Carter-Wegman MAC since it is actually very close to the real construction:

1. Each instance is parameterized by a polynomial hash function $$H_\texttt{poly}$$ defined over finite field $$\mathbb{F}$$ and max message length $$L$$, and a pseudorandom function $$F$$ defined over some key space $$\mathcal{K}_F$$, some input space $$\mathcal{R}$$, and whose output space is also $$\mathbb{F}$$. The MAC key $$k = (k_H, k_F)$$ is a tuple of a field element $$k_H \in \mathbb{F}$$ and a PRF key $$k_F \in \mathcal{K}_F$$
2. **Signing:** given message $$m = (m_1, m_2, \ldots, m_l)$$, sample a uniformly random $$r \stackrel{\$}{\leftarrow} \mathcal{R}$$, the compute $$t \leftarrow H_\texttt{poly}(k_H, m) + \texttt{PRF}(k_F, r)$$. Output $$(t, r)$$ as the tag.
3. **Verifying:** re-run the signing routine, except that we use the $$r$$ in the tag instead of sampling a random one. The the tag is valid if and only if the recomputed tag is identical to the input tag.

If the input PRF is computationally indistinguishable from a truly random function (think AES), then the sum of a polynomial hash and the output of the PRF is computationally indistinguishable from a truly random field element (we claim without proof that the some of a uniformly random variable with any other random variable is a uniformly random variable, though this should be easy to verify). This meaningfully hides information about the secret key, so the trivial key-recovery attack is no longer feasible.

Unfortunately, this construction remains insecure. This time the weakness lies in the construction of the polynomial hash: while it is difficult for an adversary to find two distinct inputs with identical output, it is easy for an adversary to find two distinct inputs whose output are predictably related. This allows an adversary to obtain the tag of some chosen message, then forge a tag for a distinct but related message. Here is how the forgery works:

1. Adversary $$A$$ picks some message $$m = (m_1, m_2, \ldots, m_l)$$ and query the corresponding tag $$(t, r)$$.
1. $$A$$ samples a random field element $$m_l^\prime \stackrel{\$}{\leftarrow} \mathbb{F}$$ and constructs a new message $$m^\prime = (m_1, m_2, \ldots, m_l^\prime)$$ by replacing $$m_l$$ with $$m_l^\prime$$.
1. $$A$$ present $$(m^\prime, (t - m_l + m_l^\prime, r))$$ as the forged message-tag pair. It should be easy to verify that $$H_\texttt{poly}(k, m) - H_\texttt{poly}(k, m^\prime) = m_l - m_l^\prime$$, so $$t - m_l + m_l^\prime = H_\texttt{poly}(k_H, m^\prime) + \texttt{PRF}(k_F, r)$$

# Attempt 3: the Carter-Wegman MAC
From attempt 2 we know that $$H_\texttt{poly}$$ is weak because it's easy for an adversary to produce distinct inputs whose outputs are predictably related. Specifically we say that $$H_\texttt{poly}$$ is **difference predictable**. On the other hand, the secure construction will be called **difference unpredictable function (DUF)**. We will present an improvement over $$H_\texttt{poly}$$ that is a (zero-time) DUF, then show that using a zero-time DUF in the "hash-then-PRF" gives us a MAC that achieves existential unforgeability under chosen message attack.

The improved polynomial hash is as follows:

$$
H_\texttt{xpoly}(k_H, m) = k \cdot H_\texttt{poly}(k_H, m) = k^{l+1} + k^l\cdot m_1 + \ldots + k \cdot m_l
$$

If an adversary can produce distinct messages $$m_a = (a_1, a_2, \ldots, a_u), m_b = (b_1, b_2, \ldots, b_v)$$ such that their outputs differ by some known value $$\delta$$, then the adversary has crafted two polynomials $$h_a(k) = k^{u+1} + k^{u} \cdot a_1 + \ldots + k \cdot a_u$$ and $$h_b(k) = k^{v+1} + k^{v} \cdot b_1 + \ldots + k \cdot b_v$$ such that: 

$$
h_a(k) - h_b(k) - \delta = 0
$$

The L.H.S. of the equation is a polynomial of at most degree $$L+1$$, so for a uniformly random key $$k \in \mathbb{F}$$, the probability that $$k$$ is a root of the polynomial on the L.H.S. is at most $$\frac{L+1}{\vert \mathbb{F} \vert}$$. This means that even for computationally unbounded adversaries, the probability of finding predictable difference in outputs can be made negligible with appropriate choice of $$L$$ and $$\mathbb{F}$$.

Finally, we present a sketch of proof that a Carter-Wegman MAC constructed using a DUF is EUF-CMA. We use a technique called "sequence of games", in which we incrementally transform the standard EUF-CMA game with a different game and account for the possibilities that an adversary can tell the difference between games in which step of the transformation. We begin with the standard EUF-CMA game, which we call game 0.

1. In game 1, we slightly modify the signing oracle such that distinct message queried are always signed with distinct nonces $$r$$. Game 1 and game 0 are indistinguishable by the adversary, unless the signing oracle signs distinct queries with the same nonce, which happens with probability at most $$\frac{Q^2}{\vert \mathcal{R} \vert}$$.
1. In game 2, we further modify the signing oracle such that for each signing query $$m$$, the output $$(t, r)$$ is such that $$t \stackrel{\$}{\leftarrow} \mathcal{T}$$ is a uniformly random element. The modified oracle keeps track of the inputs so that for the same message, the same tag is returned all the time. This way the modified oracle maintains a consistent output. If game 2 and game 1 are distinguishable by the forgery adversary, then we can build a second adversary to distinguish the PRF from uniformly random function using the forgery adversary as a subroutine.

A successful forgery $$(m, (t, r))$$ against game 2 falls into two possibilities:

1. the forgery uses a fresh nonce $$r$$ that was never used before. Considering that the PRF is indistinguishable from uniformly random, we argue that the correct tag is also indistinguishable from a uniformly random field element, so the probability that the forgery is valid is at most $$\frac{1}{\vert\mathcal{T}\vert}$$
1. the forgery uses a nonce that has already been seen in a signin query $$(\tilde{m}, (\tilde{t}, r))$$. In this case the adversary has found distinct inputs $m \neq \tilde{m}$ such that $$H_\texttt{xpoly}(k_H, m) - H_\texttt{xpoly}(k_H, \tilde{m}) = t - \tilde{t}$$ can be known without knowing the secret key $$k_H$$. In other words, the keyed hash function is not DUF.

In conclusion, $$\texttt{MAC}((k_H, k_F), m) = H(k_H, m) + \texttt{PRF}(k_F, r)$$ is EUF-CMA if:

- $$\texttt{PRF}$$ is computationally indistinguishable from uniformly random
- $$H$$ is DUF
- A distinct nonce $$r$$ is used for distinct messages

# Carter-Wegman MAC in practice, conclusion
Some well-known examples of Carter-Wegman MAC are used in AES-GCM (with $$\mathbb{F} = GF(2^{128})$$ and PRF being AES) and ChaCha20-Poly1305 (with $$\mathbb{F} = \mathbb{F}_q$$ where $$q = 2^{130} + 5$$ and PRF being ChaCha20's round functions). 

It's important that nonce is never reused, or the MAC can be broken. In real-time usage, this is achieved at the protocol level. For example, in TLS the nonce is a message counter that the client and server each keep track of (so the nonce is actually NOT transmitted in the authenticated encryption ciphertext).

Compared to other MAC constructions like ECBC-MAC and HMAC, Carter-Wegman MAC enjoys great performance advantage. This is especially true where hardware acceleration for finite field arithmetics is supported.
