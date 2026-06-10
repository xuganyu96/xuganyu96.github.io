---
layout: post
title: Newton's identity
date: 2026-06-10 15:33:09 -0400
category: cryptography
tags: hqc
---

Newton's identity is useful for connecting the syndrome of Reed-Solomon codes
and Berlekamp-Massey's algorithm for computing the minimal linear feedback
shift register (LFSR). Here we present a formulation and proof as a lemma for
future use.

## Statement

For positive integers $$l, t$$, define

$$
\begin{equation}
S_l = \sum_{i=1}^t e_ia_i^l
\end{equation}
$$

where $$e_i, a_i \in \mathbb{F}$$ for some field $$\mathbb{F}$$. In other words:

$$
\begin{aligned}
S_1 &= e_1a_1 + e_2a_2 + \ldots + e_ta_t \\
S_2 &= e_1a_1^2 + e_2a_2^2 + \ldots + e_ta_t^2 \\
    &\ldots
\end{aligned}
$$

Define $$\sigma(x)\in\mathbb{F}[x]$$ to be:

$$
\begin{equation}
    \sigma(x) = \prod_{i=1}^t (1 - a_ix)
\end{equation}
$$

Denote the coefficients of $$\sigma(x)$$ by
$$\sigma_0, \sigma_1, \ldots, \sigma_t$$. In other words:

$$
\begin{equation}
    \sigma(x) = \sigma_0 + \sigma_1 x + \ldots + \sigma_t x^t
\end{equation}
$$

Then for all $$l > t$$:

$$
\begin{equation}
    \sum_{i=0}^t \sigma_i S_{l-i} = 0
\end{equation}
$$

## Proof

We will prove by induction on $$t > 0$$.

### Base case

For $$t = 1$$ and $$l > t$$, $$S_l = e_1a_1^l, S_{l-1} = e_1a_1^{l-1}$$.
By the definition of $$\sigma$$ we know $$\sigma_0 = 1$$ and 
$$\sigma_1 = -a_1$$. It is straightforward to verify that for all $$l > t$$:

$$
\begin{equation}
    S_l\sigma_0 + S_{l-1}\sigma_1 = e_1a_1^l - e_1a_1^{l-1}a_1 = 0
\end{equation}
$$

### Induction

Let $$l, t$$ be some positive integers. Define

$$
\begin{equation}
    S_l^{(t)} = \sum_{i=1}^t e_ia_i^l
\end{equation}
$$

and

$$
\begin{equation}
    \sigma^{(t)}(x) = \prod_{i=1}^t (1 - a_i x) = \sum_{i=0}^t \sigma^{(t)}_i x^i
\end{equation}
$$

We will show the inductive step by proving that if the conclusion holds for
$$S^{(t)}, \sigma^{(t)}$$, then it also holds for $$S^{(t+1)}, \sigma^{(t+1)}$$

$$
\begin{equation}
\left(
    l > t \implies \sum_{i=0}^t \left(
        \sigma^{(t)}_i S^{(t)}_{l - i}
    \right) = 0
\right) \implies \left(
    l > t+1 \implies \sum_{i=0}^t \left(
        \sigma^{(t+1)}_i S^{(t+1)}_{l - i}
    \right) = 0
\right)
\end{equation}
$$

<!-- TODO: finis this -->

## References

- [Wikipedia](https://en.wikipedia.org/wiki/Newton%27s_identities#Mathematical_statement)