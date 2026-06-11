---
layout: post
title: Newton's identity
date: 2026-06-10
category: cryptography
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
    l > t+1 \implies \sum_{i=0}^{t+1} \left(
        \sigma^{(t+1)}_i S^{(t+1)}_{l - i}
    \right) = 0
\right)
\end{equation}
$$

The goal with this induction is to rewrite $$S^{(t+1)}$$ and $$\sigma^{(t+1)}$$
terms with $$S^{(t)}$$, $$\sigma^{(t)}$$, $$e_{t+1}$$, and $$a_{t+1}$$.

Rewriting $$S^{(t+1)}$$ is straightforward:

$$
\begin{equation}
\forall l > 0 :
S^{(t+1)}_l = \sum_{i=1}^{t+1} e_i a_i^l
= \left(\sum_{i=1}^{t} e_i a_i^l\right) + e_{t+1}a_{t+1}^l
= S^{(t)}_l + e_{t+1}a_{t+1}^l
\end{equation}
$$

From the definition of $$\sigma(x)$$ we know that
$$\sigma_0^{(t)} = \sigma_0^{(t+1)} = 1$$. For degree $$d > 0$$,
$$\sigma_d^{(t+1)}$$ is the coefficient of the $$d$$-power term, which is the
sum of products of $$d$$ distinct elements from the set

$$A = \left\{ -a_i \mid 1 \leq i \leq t+1 \right\}$$

We can partition the terms
in this sum depending on whether $$a_{t+1}$$ if a factor:

$$
\begin{aligned}
\sigma^{(t+1)}_d 
&= \sum_{
        \text{distinct }a_{j_1},a_{j_2},\ldots,a_{j_d} \in A
} a_{j_1}a_{j_2}\ldots a_{j_d} \\
&= \sum_{
        \text{distinct }a_{j_1},a_{j_2},\ldots,a_{j_d} \in A/\{a_{t+1}\}
} a_{j_1}a_{j_2}\ldots a_{j_d}
    + (-a_{t+1})\cdot\left(
        \sum_{
        \text{distinct }a_{j_1},a_{j_2},\ldots,a_{j_{d-1}} \in A/\{a_{t+1}\}
    } a_{j_1}a_{j_2}\ldots a_{j_{d-1}}
    \right) \\
&= \sigma^{(t)}_d + (-a_{t+1})\sigma^{(t)}_{d-1}
\end{aligned}
$$

Note that for $$d = t+1$$, $$\sigma^{(t)}_d = \sigma^{(t)}_{t+1} = 0$$ because
$$\sigma^{(t)}(x)$$ has no term with degree $$t+1$$. This is consistent with
the inductive relationship above:

$$
\begin{equation}
    \sigma^{(t+1)}_{t+1} = (-a_{t+1})\sigma^{(t)}_t
\end{equation}
$$

Here is a summary of all the inductive building blocks:

$$
\begin{equation}
S^{(t+1)}_l = S^{(t)}_l + e_{t+1}a_{t+1}^l
\end{equation}
$$

$$
\begin{equation}
\sigma_0^{(t)} = \sigma_0^{(t+1)} = 1
\end{equation}
$$

$$
\begin{equation}
\forall d > 0 : \sigma^{(t+1)}_d = \sigma^{(t)}_d + (-a_{t+1})\sigma^{(t)}_{d-1}
\end{equation}
$$

Given positive integer $$l > t+1$$, we will now compute and show that

$$
\begin{equation}\label{eq:induct-concl}
\sum_{i=0}^{t+1} \sigma^{(t+1)}_i S^{(t+1)}_{l-i} = 0
\end{equation}
$$

First split the sum between $$i=0$$ and $$1\leq i \leq t+1$$, then rewrite using
the inductive assumptions:

$$
\begin{equation}\label{eq:induct-compute}
\begin{aligned}
&\sum_{i=0}^{t+1} \sigma^{(t+1)}_i S^{(t+1)}_{l-i} \\
&= (\sigma^{(t+1)}_0 S^{(t+1)}_{l})
    + \sum_{i=1}^{t+1} \sigma^{(t+1)}_i S^{(t+1)}_{l-i} \\
&= (S^{(t)}_l + e_{t+1} a^l_{t+1}) + \sum_{i=1}^{t+1}\left(
        \sigma^{(t)}_i + (-a_{t+1})\sigma^{(t)}_{i-1} 
    \right)\left(
        S^{(t)}_{l-i} + e_{t+1}a_{t+1}^{l-i}
    \right)
\end{aligned}\end{equation}
$$

Let's zoom in on the summation of the RHS:

$$
\begin{equation}\label{eq:subsums}
\begin{aligned}
& \sum_{i=1}^{t+1}\left(
        \sigma^{(t)}_i + (-a_{t+1})\sigma^{(t)}_{i-1} 
    \right)\left(
        S^{(t)}_{l-i} + e_{t+1}a_{t+1}^{l-i}
    \right) \\
&= \sum_{i=1}^{t+1}\left(
    \sigma^{(t)}_i S^{(t)}_{l-i}
    - a_{t+1}\sigma^{(t)}_{i-1}S^{(t)}_{l-i}
    + e_{t+1} a^{l-i}_{t+1}\sigma^{(t)}_i
    - e_{t+1} a^{l-(i-1)}_{t+1}\sigma^{(t)}_{i-1}
\right) \\
&= \sum_{i=1}^{t+1}\left(
        \sigma^{(t)}_i S^{(t)}_{l-i}
    \right)
    + \sum_{i=1}^{t+1}\left(
        - a_{t+1}\sigma^{(t)}_{i-1}S^{(t)}_{l-i}
    \right)
    + e_{t+1} \sum_{i=1}^{t+1}\left(
         a^{l-i}_{t+1}\sigma^{(t)}_i
        - a^{l-(i-1)}_{t+1}\sigma^{(t)}_{i-1}
    \right)
\end{aligned}
\end{equation}
$$

For the first sub-summation, we take advantage of the fact that
$$\sigma^{(t)}_{t+1} = 0$$:

$$
\begin{equation}\label{eq:subsum-1}
\begin{aligned}
\sum_{i=1}^{t+1} \sigma^{(t)}_i S^{(t)}_{l-i}
&= \left(
        \sum_{i=1}^t \sigma^{(t)}_i S^{(t)}_{l-i}
    \right)
    + \sigma^{(t)}_{t+1}S^{(t)}_{l-(t+1)} \\
&= -S^{(t)}_l
\end{aligned}
\end{equation}
$$

For the second sub-summation, we do a change of variable from $$i-1$$ to $$i$$,
then take advantage of the fact that $$l > t+1$$, which means $$l - 1 > t$$:

$$
\begin{equation}\label{eq:subsum-2}
\begin{aligned}
\sum_{i=1}^{t+1}\left(
    - a_{t+1}\sigma^{(t)}_{i-1}S^{(t)}_{l-i}
\right)
&= -a_{t+1}\sum_{i=1}^{t+1}\left(
    \sigma^{(t)}_{i-1}S^{(t)}_{l-i}
\right) \\
&= -a_{t+1}\sum_{i=0}^{t}\left(
    \sigma^{(t)}_{i}S^{(t)}_{(l-1)-i}
\right) \\
&= 0
\end{aligned}
\end{equation}
$$

The same trick applies to the third sub-summation:

$$
\begin{equation}\label{eq:subsum-3}
\begin{aligned}
& e_{t+1} \sum_{i=1}^{t+1}\left(
    a^{l-i}_{t+1}\sigma^{(t)}_i
    - a^{l-(i-1)}_{t+1}\sigma^{(t)}_{i-1}
\right) \\
&= e_{t+1} \left(
    \sum_{i=1}^{t+1}\left(
        a^{l-i}_{t+1}\sigma^{(t)}_i
    \right)
    - \sum_{i=1}^{t+1}\left(
        a^{l-(i-1)}_{t+1}\sigma^{(t)}_{i-1}
    \right)
\right) \\
&= e_{t+1} \left(
    \sum_{i=1}^{t+1}\left(
        a^{l-i}_{t+1}\sigma^{(t)}_i
    \right)
    - \sum_{i=0}^{t}\left(
        a^{l-i}_{t+1}\sigma^{(t)}_{i}
    \right)
\right) \\
&= e_{t+1} \left(
    a^{l-(t+1)}_{t+1}\sigma^{(t)}_{t+1}
    - a^{l}_{t+1}\sigma^{(t)}_{0}
\right) \\
&= e_{t+1} \left(
    a^{l-(t+1)}_{t+1}\cdot 0
    - a^{l}_{t+1}\cdot 1
\right) \\
&= -e_{t+1}a_{t+1}^{l}
\end{aligned}
\end{equation}
$$

Combining equations
$$\ref{eq:induct-compute}$$, $$\ref{eq:subsums}$$, $$\ref{eq:subsum-1}$$,
$$\ref{eq:subsum-2}$$, and $$\ref{eq:subsum-3}$$ gives us the desired result
(equation $$\ref{eq:induct-concl}$$).

## References

- [Wikipedia](https://en.wikipedia.org/wiki/Newton%27s_identities#Mathematical_statement)