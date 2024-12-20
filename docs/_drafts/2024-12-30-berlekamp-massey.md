---
layout: post
title:  "The Berlekamp-Massey algorithm"
date: 2024-12-30 10:09:24 -0500
categories: cryptography
---

The Berlekamp-Massey algorithm is a versatile algorithm that was first introduced by Elwin Berlekamp in 1968 to decode BCH code, then improved on by James Massey in 1969 for computing the shortest LFSR that generates a given sequence. In this post I will describe the algorithm from the perspective of computing shortest LFSR, then explain why this algorithm works.

We denote a length-$$L$$ linear feedback shift register (LFSR) by its **connection coefficients** $$(c_1, c_2, \ldots, c_L)$$ and its seed values $$(s_0, s_1, \ldots, s_{L-1})$$. Beyond the seed values, the following relationship holds:

$$
s_j + \sum_{i=1}^L c_is_{j-i} = 0 \; (j \geq L)
$$

We also define the **connection polynomial** of a length-$$L$$ LFSR $$(c_1, c_2, \ldots, c_L)$$ by:

$$
C(x) = 1 + c_1x + c_2x^2 + \ldots + c_Lx^L
$$

Notice that the degree of the connection polynomial is the length of the corresponding LFSR. This is important because later on we will construct new LFSR by constructing the corresponding connection polynomial, and we need to think about its length by discussing the degree of the connection polynomial.

Let $$s = (s_0, s_1, \ldots)$$ be an infinite sequence. Let $$L_n(s)$$ denote the length of the shortest LFSR that generates the first $$n$$ digits of the sequence $$s_0, s_1, \ldots, s_{n-1}$$ (where there is no ambiguity with $$s$$ I will use the shorthand $$L_n$$). We are interested in finding an LFSR with length $$L_n$$.

The LFSR synthesis algorithm takes as input a finite sequence $$(s_0, s_1, \ldots, s_{N-1})$$ and output a shortest LFSR with length $$L_N$$ that generates this sequence:

1. Initialize the state $$C(x) \leftarrow 1, n \leftarrow 0, l \leftarrow 0, B(x) \leftarrow 1, d_m \leftarrow 1, y \leftarrow 1$$. We will iteratively build $$C(x)$$ to be the shortest LFSR, with $$l$$ tracking the length of this LFSR and $$n$$ tracking the number of digits this LFSR can correctly generate. $$B(x), d_m, y$$ will be explained later.
2. If $$n = N$$, terminate and return $$C(x)$$ as the connection polynomial of a shortest LFSR; otherwise proceed.
3. Let $$d = s_n + \sum_{i=1}^l c_is_{n-i}$$, if $$d = 0$$, then set $$y \leftarrow y + 1$$
4. If $$d \neq 0$$ and $$2l \geq 
