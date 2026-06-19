---
layout: post
title: The Berlekamp-Massey algorithm
date: 2026-06-19 16:33:44 -0400
---

## Definitions

A **L**inear **F**eedback **S**hift **R**egister (LFSR) of non-negative length
$$L$$ is parameterized by $$L$$ initial stages $$S_1, S_2, \ldots, S_L$$ and
$$L$$ connection cofficients $$\sigma_1, \sigma_2, \ldots, \sigma_L$$. It
generates an infinite sequence $$S_1, S_2, \ldots, S_L, S_{L+1}, \ldots$$ such
that the first $$L$$ elements are the initial stages, and all subsequent
elements are linear combination of the previous $$L$$ elements:

$$
\begin{equation}\label{eq:lfsr-def}
l > L \implies S_l + \sum_{i=1}^L S_{l-i}\sigma_i = 0
\end{equation}
$$

We define the **connection polynomial** $$\sigma(x)$$ to be:

$$
\sigma(x) = 1 + \sum_{i=1}^L \sigma_i x^i
$$

A zero-length LFSR generates a infinite sequence of $$0$$'s.

We are interested solving the problem of finding a shortest LFSR that generates
a given finite sequence of length $$N$$: $$S_1, S_2, \ldots, S_N$$. We will
state and prove some auxiliary results, then describe the algorithm.

## Lemma: A lower bound for length of shortest LFSR

For $$1 \leq n \leq N$$, denote the subsequence that contains the first $$n$$
elements by $$S^{(n)}$$. Denote the length of the shortest LFSR that generates
$$S^{(n)}$$ by $$L^{(n)}$$. Denote the connection polynomial of a shortest
LFSR by $$\sigma^{(n)}(x)$$.

We claim that if there is a LFSR with length $$L$$ that generates $$S^{(n)}$$
but not $$S^{(n+1)}$$, then the length $$L^\prime$$ of any LFSR that generates
$$S^{(n+1)}$$ is bounded below by:

$$
\begin{equation}\label{eq:lemma-1}
L^\prime \geq n + 1 - L
\end{equation}
$$

**Proof**: let $$\sigma(x)$$ be the connection polynomial of the length $$L$$
LFSR that generates $$S^{(n)}$$ but not $$S^{(n+1)}$$. Let $$\sigma^\prime(x)$$
be the connection polynomial of the LFSR that generates $$S^{(n+1)}$$. From
the hypothesis of the lemma, we have the following equations:

$$
\begin{equation}\label{eq:lemma-1-1}
(L < i \leq n) \implies (S_i + \sum_{j=1}^L S_{i-j}\sigma_j = 0)
\end{equation}
$$

$$
\begin{equation}\label{eq:lemma-1-2}
S_{n+1} + \sum_{j=1}^L S_{n+1-j}\sigma_j \neq 0
\end{equation}
$$

$$
\begin{equation}\label{eq:lemma-1-3}
(L^\prime < i \leq n+1)
\implies (S_i + \sum_{j=1}^{L^\prime} S_{i-j}\sigma^\prime_j = 0)
\end{equation}
$$

For $$1 \leq j \leq L$$, $$n + 1 - L \leq n + 1 - j \leq n$$, so if
$$L^\prime < n + 1 - L$$, then $$L^\prime < n + 1 - j \leq n$$, which means that
$$n + 1 - j$$ falls in the range of the hypothesis in equation
$$\ref{eq:lemma-1-3}$$. Therefore, we can rewrite the LHS of Equation
$$\ref{eq:lemma-1-2}$$:

$$
\begin{equation}\label{eq:lemma-1-2-rewrite}
\begin{aligned}
S_{n+1} + \sum_{j=1}^L S_{n+1-j}\sigma_j
&= S_{n+1} + \sum_{j=1}^L \left(
    -\sum_{j^\prime=1}^{L^\prime} S_{n+1-j-j^\prime}\sigma^{\prime}_{j^\prime}
\right)\sigma_j \\
&= S_{n+1} -
    \sum_{j=1}^L \sigma_j
        \sum_{j^\prime = 1}^{L^\prime} \sigma^{\prime}_{j^\prime}
        S_{n+1-j-j^\prime} \\
&= S_{n+1} -
    \sum_{j^\prime = 1}^{L^\prime} \sigma^{\prime}_{j^\prime}
        \sum_{j=1}^L \sigma_j
        S_{n+1-j^\prime-j} \\
\end{aligned}
\end{equation}
$$

By similar logic as above, we know that $$L \leq n + 1 - j^\prime \leq n$$, so
by Equation $$\ref{eq:lemma-1-1}$$:

$$
\begin{equation}\label{eq:lemma-1-2-rewrite-2}
\sum_{j=1}^L \sigma_j S_{n+1-j^\prime-j} = -S_{n+1-j^\prime}
\end{equation}
$$

We can use that to further rewrite the RHS of Equation
$$\ref{eq:lemma-1-2-rewrite}$$:

$$
\begin{equation}\label{eq:lemma-1-2-rewrite-3}
\begin{aligned}
S_{n+1} -
    \sum_{j^\prime = 1}^{L^\prime} \sigma^{\prime}_{j^\prime}
        \sum_{j=1}^L \sigma_j
        S_{n+1-j^\prime-j}
&= S_{n+1} +
    \sum_{j^\prime=1}^{L^\prime} \sigma^{\prime}_{j^\prime} S_{n+1-j^\prime} \\
&= 0
\end{aligned}
\end{equation}
$$

Combining Equations $$\ref{eq:lemma-1-2-rewrite}$$ and
$$\ref{eq:lemma-1-2-rewrite-3}$$ gives the following:

$$
\begin{equation}
S_{n+1} + \sum_{j=1}^L S_{n+1-j}\sigma_j = 0
\end{equation}
$$

This contradicts Equation $$\ref{eq:lemma-1-2}$$. Therefore, the assumption
$$L^\prime < n + 1 - L$$ must be false.

It is easy to see that $$L^{(n+1)} \geq L^{(n)}$$ since any LFSR that generates
$$S^{(n+1)}$$ must also generate $$S^{(n)}$$. Combine this with the lemma above
gives us the following lower bound:

$$
\begin{equation}\label{eq:lemma-2}
L^{(n+1)} \geq \max\left(L^{(n)}, n + 1 - L^{(n)}\right)
\end{equation}
$$

<!-- TODO: continue with iteractive algorithm -->