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

## Theorem: tightening the lower bound for length of shortest LFSR

Equation $$\ref{eq:lemma-2}$$ established a lower bound on the length of the
shortest LFSR for a given sequence of length $$n$$. Here we show that this lower
bound is tight: the length of the shortest LFSR that generates $$S^{(n+1)}$$ is
exactly the maximum between $$L^{(n)}$$ and $$n + 1 - L^{(n)}$$:

$$
\begin{equation}\label{eq:theorem-1}
L^{(n+1)} = \max\left(L^{(n)}, n + 1 - L^{(n)}\right)
\end{equation}
$$

We will prove by induction.

Let's begin with the base cases. The shortest LFSR that generates an empty
sequence is the empty LFSR. Let $$n>0$$. If $$S^{(n)}$$ consists of all $$0$$'s,
then the shortest LFSR is the empty LFSR with a length of $$0$$. If $$S^{(n)}$$
is such that for $$0 < i < n$$, $$S_i = 0$$ and $$S_n \neq 0$$, then the length
of the shortest LFSR is exactly $$n$$, because any LFSR with length less than
$$n$$ has initial stages that are all $$0$$'s, so it can only generate $$0$$'s
afterwards. It is easy to see that in each case, Equation $$\ref{eq:theorem-1}$$
holds:

- If $$S^{(n)}$$ and $$S^{(n+1)}$$ are both zero sequence, then
  $$L^{(n)} = L^{(n+1)} = 0$$
- If $$S^{(n)}$$ is zero sequence and $$S^{(n+1)}$$ is not, then $$L^{(n)} = 0$$
  and $$L^{(n+1)} = n+1$$

For the inductive step, the inductive hypothesis states that we have found the
shortest LFSR for each of the subsequence $$S^{(0)}, S^{(1)}, \ldots, S^{(n)}$$
in the form of a connection polynomial
$$\sigma^{(0)}, \sigma^{(1)}, \ldots, \sigma^{(n)}$$ AND that Equation
$$\ref{eq:theorem-1}$$ holds for all of them:

$$
\begin{equation}\label{eq:thm1-induct-hyp}
(0 \leq i < n) \implies (L^{(i+1)} = \max(L^{(i)}, i+1-L^{(i)}))
\end{equation}
$$

We want to construct the connection polynomial for the shortest LFSR that
generates $$S^{(n+1)}$$ and show that the equality holds.

If $$\sigma^{(n)}$$ generates $$S^{(n+1)}$$, then by the monotonicity of $$L$$,
$$\sigma^{(n)}$$ is the shortset LFSR that generates $$S^{(n+1)}$$. In other
words, $$\sigma^{(n+1)} = \sigma^{(n)}$$ and $$L^{(n+1)} = L^{(n)}$$, and we
are done.

If $$\sigma^{(n)}$$ does not generate $$S^{(n+1)}$$, then there exists a
non-zero difference between $$S_{n+1}$$ and what $$\sigma^{(n)}$$ generates for
the $$n+1$$-th element:

$$
\begin{equation}\label{eq:diff-n+1}
d_{n+1} = S_{n+1} + \sum_{i=1}^{L^{(n)}} S_{n+1-i}\sigma^{(n)}_i \neq 0
\end{equation}
$$

Let $$m < n$$ denote the length of the subsequence BEFORE the latest LFSR length
change. In other words: $$L^{(m)} < L^{(m+1)} = L^{(n)}$$. We can safely assume
such $$m$$ to exist, because if such $$m$$ does not exist, then $$L^{(n)}$$ must
be equal to $$L^{(0)} = 0$$, which means that $$S^{(n)}$$ is a zero sequence
while $$S^{(n+1)}$$ is a non-zero sequence. We have already covered this case in
the base case.

Because $$L^{(m)} < L^{(m+1)}$$, we know that $$\sigma^{(m)}$$ does not generate
$$S^{(m+1)}$$, so the difference term $$d_{m+1}$$ is similarly non-zero:

$$
\begin{equation}\label{eq:diff-m+1}
d_{m+1} = S_{m+1} + \sum_{i=1}^{L^{(m)}} S_{m+1-i}\sigma^{(m)}_i \neq 0
\end{equation}
$$

By the inductive hypothesis, we also know:

$$
\begin{equation}\label{eq:length-m-m+1}
L^{(m+1)} = \max(L^{(m)}, m+1-L^{(m)}) = m+1-L^{(m)}
\end{equation}
$$