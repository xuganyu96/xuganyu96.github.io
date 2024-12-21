---
layout: post
title:  "The Berlekamp-Massey algorithm"
date: 2024-12-30 10:09:24 -0500
categories: cryptography
---

The Berlekamp-Massey algorithm is a versatile algorithm that was first introduced by Elwin Berlekamp in 1968 to decode BCH code, then improved on by James Massey in 1969 for computing the shortest LFSR that generates a given sequence. In this post I will describe the algorithm from the perspective of computing shortest LFSR, then explain why this algorithm works.

A length-$$L$$ LFSR is defined by its **connection coefficients** $$(c_1, c_2, \ldots, c_L)$$ and the seed values $$(s_0, s_1, \ldots, s_{L-1})$$. The first $$L$$ digits of its output sequence are the seed values, then for $$j \geq L$$:

$$
s_j + \sum_{i=1}^Lc_is_{j-i} = 0
$$

By convention, an empty LFSR whose connection coefficients form an empty list has length $$0$$ and outputs a sequence of all $$0$$'s.

Within the context of this post, we are interested in the problem of constructing an LFSR that generates a given finite sequence. For any non-empty input sequence $$s_0, s_1, \ldots, s_{N-1}$$ of length $$N$$, there is a trivial LFSR construction with length $$N$$ that simply sets the seed to be equal to the sequence. Given some infinite sequence $$s = (s_0, s_1, \ldots)$$, let $$L_N(s)$$ denote the length of the shortest LFSR that generates the first $$N$$ digits of the sequence $$s$$, then the trivial construction shows that $$L_N(s) \leq N$$ for all $$s$$. Also by convention, $$L_0(s) = 0$$ for all $$s$$.

It is also easy to show that for any given $$s$$, $$L_{N+1}(s) > L_N(s)$$. In other words, *the length of the shortest LFSR is monotonically non-decreasing*. This makes sense because any LFSR that generates the first $$N+1$$ digits of the input sequence also generates the first $$N$$ digits, so the shortest LFSR that generates the first $$N$$ cannot be longer than the shortest LFSR that generates the first $$N+1$$ digits.

It turns out that we can do better. In 1969 James Massey proposed the following algorithm and proved that this algorithm computes the shortest LFSR that generates the input finite sequence:

1. 