---
layout: post
title:  "Understanding extended Euclid algorithm"
date:   2025-10-16 19:20:09 -0400
categories: miscellaneous
---

Recall from basic number theory:
let $$a, b$$ be integers, 
we say $$a$$ divides $$b$$ (denoted by $$a \vert b$$) if there exists another integer $$q$$ such that $$b = qa$$.
let $$a \gt 0$$ be a positive integer and $$b \geq 0$$ be a non-negative integer,
then there exists a unique pair of integers $$q \geq 0$$ and $$0 \leq r \lt a$$ such that

$$
b = q \cdot a + r
$$

We call the process of computing $$q, r$$ by the name of **Euclidean division**.
We call $$q$$ the quotient, and $$r$$ the remainder.

Let $$a, b$$ be non-negative integers.
The **greatest common divisor (GCD)** of $$a, b$$ is the greatest integer $$d$$ such that $$d \vert a$$ and $$d \vert b$$.
Euclid's algorithm is an efficient (i.e. polynomial-time) algorithm for finding $$\gcd(a, b)$$:

1. Assume without loss of generality that $$a \geq b$$. 
If it's not true then swap $$a, b$$, which should not affect the result because $$\gcd(a, b) = \gcd(b, a)$$
1. Let $$r_0 = a, r_1 = b$$, then for each of $$i \geq 2$$, $$r_i$$ is the remainder of dividing $$r_{i-2}$$ by $$r_{i-1}$$.
1. The algorithm terminates when the this recursive procedure reaches 0, and we have $$\gcd(a, b) = r_l$$, where $$r_l$$ is the last non-zero value in the sequence $$r_0, r_1, \ldots$$.

<!-- TODO: do a proof -->

From *Bezout's Identity* we know that for non-negative integers $$a, b$$ there exists a unique pair of integers $$s, t$$ such that

$$
s\cdot a + t \cdot b = \gcd(a, b)
$$

This result is important because if $$\gcd(a, b) = 1$$, then $$s$$ is $$a$$'s multiplicative inverse under modulus $$b$$ and vice versa.
This is crucial in the RSA cryptosystem because the secret exponent is the multiplicative inverse of the public exponent:

$$
d = e^{-a} \mod \phi(N)
$$

What has bothered me a lot when I was studying cryptography and the RSA cryptosystem was how the *vanilla* Euclid's algorithm became the **extended Euclid's algorithm**, which can solve for $$s, t, \gcd(a, b)$$ at the same time.
The key to understanding is the following iterative relationship:

$$
s_ia_i + t_ib_i = r_i
$$

For initial conditions we have $$r_0 = a, r_1 = b$$, then iteratively:

$$
r_i = r_{i-2} - q_{i-1}r_{i-1}
$$