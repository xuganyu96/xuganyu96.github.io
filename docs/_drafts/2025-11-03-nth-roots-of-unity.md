---
layout: post
title:  "n-th roots of unity in finite fields"
date:   2025-11-03 11:51:55 -0500
categories: cryptography
---

Let $$F$$ be a finite field of order $$q$$. Denote its multiplicative group by $$F^\ast$$.
We know that $$ F^\ast $$ is a cyclic group of order $$q-1$$.
Let $$g \in F^\ast$$ be a generator.

A **n-th root of unity** is an element $$x \in F^\ast$$ such that:

$$
x^n = 1
$$

Any element can be represented as some $$j$$-th power of $$g$$ where $$1 \leq j \leq q-1$$.
$$g^j = 1$$ if and only if $$jn \equiv 0 \mod q-1$$.
Let $$d = \gcd(n, q-1)$$, then:

$$
jn/d = 0 \mod (q-1)/d
$$

From the definition of $$\gcd$$ we know $$n/d$$ and $$(q-1)/d$$ are relatively prime,
so the equation above is true if and only if $$j \equiv 0 \mod (q-1)/d$$.
In other words:

> $$g^j$$ is n-th root of unity if and only if $$j$$ is divisible by $$(q-1)/d$$

From the result above it is easy to show that for any given $$1 \leq n \leq q-1$$, there are $$\gcd(n, q-1)$$ distinct n-th roots of unity.

Where $$n \vert q-1$$, there are $$n$$ distinct n-th roots of unity.
Let $$\zeta = g^{(q-1)/n}$$.

We will prove a generic result about the order of $$g^j$$ for arbitrary $$j > 0$$. 
$$(g^j)^n = 1$$ if and only if $$nj \equiv 0 \mod q-1$$, which is equivalent to 

$$
nj/\gcd(j, q-1) \equiv 0 \mod (q-1)/\gcd(j, q-1)
$$

Using the same logic as above we can deduce that $$n \equiv 0 \mod (q-1)/\gcd(j, q-1)$$.
This shows that the order of $$g^j$$ is $$(q-1)/\gcd(j, q-1)$$.
Given $$\zeta = g^{(q-1)/n}$$, we have:

$$
\lvert\zeta\rvert = \frac{q-1}{\gcd((q-1)/n, q-1)}
$$

We assumed $$n \vert q-1$$, so $$\gcd((q-1)/n, q-1) = (q-1)/n$$, which means that $$\lvert\zeta\rvert = n$$.
In other words, $$\zeta$$ is a *primitive n-th root of unity*.

What about other n-th roots of unity? Any n-th root of unity can be expressed as $$\zeta^k$$ for some $$1\leq k \leq n$$.
Applying the same logic to $$\zeta^k = g^{k(q-1)/n}$$, we get:

$$
\lvert \zeta^{k} \rvert = \frac{q-1}{\gcd(k(q-1)/n, q-1)}
= \frac{q-1}{(q-1)/n \cdot \gcd(k, n)}
= \frac{n}{\gcd(k, n)}
$$

So $$\zeta^k$$ is a primitive n-th root of unity if and only if $$\gcd(k, n) = 1$$.
In other words, there are $$\phi(n)$$ distinct primitive n-th roots of unity.
