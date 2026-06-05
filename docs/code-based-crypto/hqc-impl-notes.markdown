---
layout: page
title: HQC impl reading notes
---

# What's missing:

- [ ] $$k < n - d + 1$$, $$t = \lfloor(d-1)/2\rfloor$$
- [ ] primitive root of finite field     

---

# Key generation

KEM key generation routine is a thin wrapper around PKE key generation routine.
The PKE key generation routine works with four vectors $$\mathbf{x}, \mathbf{y},
\mathbf{h}, \mathbf{s}$$. Each vector is an element in the finite field
$$\mathbb{F}_2^n$$ (or equivalently in the polynomial ring $$R =
\mathbb{F}_2\left[x\right] / \langle x^n - 1 \rangle$$). In the reference
implementation, they are typed with `uint64_t[VEC_N_SIZE_64]`, where
`VEC_N_SIZE_64 = CEIL_DIV(PARAM_N, 64)`.

| parameter | code length $$n$$ | `VEC_N_SIZE_64` |
| --------- | ----------------- | --------------- |
| HQC-1     | 17669             | 277             |
| HQC-3     | 35851             | 561             |
| HQC-5     | 57637             | 901             |

$$\mathbf{x}, \mathbf{y} \stackrel{\$}{\leftarrow} \mathcal{B}_\omega$$ are
sampled from the ball with Hamming weight $$\omega$$, where $$\omega$$ is 66,
100, 131 for the three security levels respectively.

There are two sampling routines in HQC. `vect_sample_fixed_weight1`
($$\text{SampleFixedWeightVect\$}$$ in written spec) samples fixed-weight vector
uniformly, but uses rejection sampling. It is used in key generation.
`vect_sample_fixed_weight2` ($$\text{SampleFixedWeightVect}$$) samples
fixed-weight vectors without using rejection sampling, but the output is slightly
biased. This sampling routine is used in encryption. The specification claims
that the bias does not affect the security of the scheme.

<!-- TODO: how does vect_sample_fixed_weight1/2 sample fixed-weight vectors -->

$$\mathbf{h} \stackrel{\$}{\leftarrow} \mathbb{F}_2^n$$ is uniformly randomly
sampled.

Finally $$\mathbf{s} \leftarrow \mathbf{y}\cdot\mathbf{h} + \mathbf{x}$$. Here
the arithmetics are all performed in the polynomial ring. The multiplication is
big enough to actually warrant using Karatsuba.

A summary of data flow:

```
ek_seed, dk_seed ← keygen_seed
h ← ek_seed
x, y ← dk_seed
s ← h, x, y
ek ← ek_seed, s
dk ← dk_seed
```

---

# Encryption

Similar to key generatino, the KEM encapsulation routine is a thin wrapper
around the PKE encryption routine.

The encryption routines begins with sampling three fixed weight vectors

$$
\begin{aligned}
\mathbf{r}_1, \mathbf{r}_2 &\stackrel{\$}{\leftarrow} \mathcal{B}_{\omega_r} \\
\mathbf{e} &\stackrel{\$}{\leftarrow} \mathcal{B}_{\omega_e}
\end{aligned}
$$

All three vectors are in $$\mathbf{F}_2^n$$ and sampled using the slightly biased
`vect_sample_fixed_weight2`.

The ciphertext consists of two components:

$$
\begin{aligned}
    \mathbf{u} &\leftarrow \mathbf{r}_1 + \mathbf{h} \cdot \mathbf{r}_2 \\
    \mathbf{v} &\leftarrow \texttt{C.Encode}(\mathbf{m}) + \texttt{Truncate}(
        \mathbf{s}\cdot\mathbf{r}_2 + \mathbf{e}, l)
\end{aligned}
$$

- $$\mathbf{r}_1, \mathbf{r}_2, \mathbf{e}$$ are the fixed-weight vectors
- $$\mathbf{h}$$ is expanded from the `ek_seed` embedded in the public key
- `m` has type `uint8_t m[PARAM_SECURITY_BYTES]`
- `C.Encode` (and conversely `C.Decode` in the decryption routine) refers to the
  error correcting code. From the type of the ciphertext (see below) we can infer
  that $$\mathbf{u}, \mathbf{v}$$ are in the finite field $$\mathbf{F}_2^n$$.
  Details for the specific choice of code can be found in [later section](#concatenation-code)

<!-- TODO: what is m's mathematical structure? -->

```c
// data_structures.h
typedef struct {
    uint64_t u[VEC_N_SIZE_64];
    uint64_t v[VEC_N_SIZE_64];
} ciphertext_pke_t;
```

---

# Concatenation code

HQC uses a concatenated code for the `C.Encode`, `C.Decode` routines.

A **concatenated code** consists of an external code and an internal code. From
a high level, encoding and decoding are function composition:

$$
\begin{aligned}
    \texttt{CatCode.Encode} &= \texttt{IntCode.Encode} \circ \texttt{ExtCode.Encode} \\
    \texttt{CatCode.Decode} &= \texttt{ExtCode.Decode} \circ \texttt{IntCode.Decode}
\end{aligned}
$$

For the external code, HQC uses **Reed-Solomon code** over $$\mathop{GF}(2^8)$$
with dimension 32.

<!-- Review Reed-Solomon code -->

---

## Reed-Solomon decoding

Let $$\mathbb{F}$$ be some finite field of characteristics $$2$$ and order $$q$$.
Let $$\alpha$$ be a primitive root of $$\mathbb{F}$$. Let $$n$$ be the chosen
code length, $$\delta$$ be the chosen error-correcting capacity such that
$$2 \delta < n$$, then we know the minimal distance to be $$d = 2 \delta + 1$$
and the message length to be $$k = n - 2\delta$$.

Define the **generating polynomial** by 

$$
g(x) = (x-\alpha)(x-\alpha^2)\ldots(x-\alpha^{2\delta})
$$

It's easy to see that $$\deg(g) = 2\delta$$. For an input message
$$m(x)\in\mathbb{F}[x]$$ where $$\deg(m) < k$$, the encoding procedure returns
a polynomial $$c(x)\in\mathbb{F}[x]$$ such that $$\deg(c) < n$$:

$$
c(x) = m(x) \cdot x^{n-k} + (m(x) \cdot x^{n-k} \mod g(x))
$$

Observe that $$g(x) \mid c(x)$$, so for $$1 \leq i \leq 2\delta$$,
$$c(\alpha^i) = 0$$.

Suppose that the received transmission is $$r(x)\in\mathbb{F}[x]$$ such that
$$\deg(r) < n$$. We know that the received transmission includes the codeword
and some errors: $$r(x) = c(x) + e(x)$$. Assume that there are exactly $$t$$
errors, which means that exactly $$t$$ coefficients in $$e(x)$$ are non-zero.
Denote the set of locations by:

$$
J = \left\{
    j \in \{0, 1, \ldots, n-1\} \mid e_j \neq 0
\right\}
$$

Observe that for $$1 \leq i \leq 2\delta$$,
$$r(\alpha^i) = c(\alpha^i) + e(\alpha^i) = e(\alpha^i)$$, so we can compute
the syndrome:

$$
S_i = r(\alpha^i) = e(\alpha^i) = \sum_{j\in J}e_j \cdot (\alpha^i)^j
$$

We want to build a (slightly modified) error-locating polynomial $$\sigma(x)$$:

$$
\sigma(x) = \prod_{j\in J}(1 + \alpha^j x)
$$

Such that $$\sigma(\alpha^j) = 0$$ if and only if $$j$$ is a location of
non-zero error.

The Berlekamp-Massey algorithm can construct
$$\sigma(x) = \sigma_0 + \sigma_1 x + \ldots + \sigma_t x^t$$ by the coefficients
$$\sigma_0, \ldots, \sigma_t$$. What relationship exists between these coefficients
and the syndromes $$S_i$$ so the BM algorithm applies?

Hint: Newton's identity??