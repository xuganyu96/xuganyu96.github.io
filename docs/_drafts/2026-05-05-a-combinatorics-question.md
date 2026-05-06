---
layout: post
title:  "The Frobenius problem"
date:   2026-05-05 14:40:21 -0400
categories: miscellaneous
tags: mathematics hol-light
---

This began as a puzzle brought up during lunch time：

> In a class of $$n \in \mathbb{N}$$ students, is it possible to divide the students into groups of 5 or 6 students?

For $$n \geq 20$$ it is always possible. The thought process is as follows:
1. It is trivially possible to divide $$n$$ students if $$ n \in \lbrace 0, 5, 6 \rbrace$$. It is trivially impossible to divide $$n$$ students if $$n \in \lbrace 1, 2, 3, 4 \rbrace$$.
1. Now consider $$n \geq 6$$: I claim without proof that it is possible to divide $$n$$ students if and only if it is possible to divide $$n - 5$$ or $$n - 6$$ students. In the forward direction, if it is possible to divide $$n \geq 6$$ students, then either there is one group with five students or one group with six students, so subtracting that group gives us a way to divide $$n - 5$$ or $$n - 6$$ students. The backward direction is similarly true by adding a group of five or six students.

With this criteria we can compute:

| $$n$$    |  $$\exists x, y \in \mathbb{N}. 5x + 6y = n$$ |
| -------- | --------------------------------------------- |
| $$0, 1, \ldots, 18 $$ |  $$ \ldots $$                    |
| 19       |  F                                            |
| 20       |  T                                            |
| 21       |  T                                            |
| 22       |  T                                            |
| 23       |  T                                            |
| 24       |  T                                            |

Since we have five consecutive yes's, all number afterwards will also be "Y".

```hl
let goal = `!n. n >= 20 ==> ?x y. 5 * x + 6 * y = n`;;

(* TODO: prove this goal *)
```

1. Is it true that if positive integers $$a, b$$ are co-prime, then for sufficiently large $$n \geq N$$, there is always **non-negative solution** $$x, y$$ to the equation $$ax + by = n$$? If yes, how can we compute the lower bound $$N$$?
1. Does it make sense to generalize to any set of positive integers $$S = \lbrace s_1, \ldots, s_n \rbrace$$?

The answer to the first question is yes, as will be described below.
There is indeed a generalized problem and it is NP hard with respect to the size of the set $$S$$ (of coin denominations).

Here is a sketch of proof for the [Frobenius coin problem](https://en.wikipedia.org/wiki/Coin_problem) where the set $$S = \lbrace a, b \rbrace$$ has two distinct elements that are co-prime.
First observe that if $$a, b$$ are not co-prime, then any integer not divisible by $$\gcd(a, b)$$ is not representable by linear combination of $$a, b$$, so there is no such lower bound $$N$$ such that $$n > N \implies \exists x, y \geq 0: ax + by = n$$.

Consider the set $$B = \lbrace kb \mid 0 \leq k < a \rbrace$$.
We claim that $$B$$ covers the all $$a$$ residue classes of $$a$$.
In other words, $$B$$ has $$a$$ elements and $$\forall 0 \leq k_i, k_j < a: k_i \neq k_j \implies k_i b \not\equiv k_jb (\mathop{\text{mod}} a)$$.
This is true because if $$0 \leq k_i, k_j < a$$ and $$ k_i \neq k_j$$, then $$-(a-1) \leq k_i - k_j \leq (a-1)$$ must be co-prime with $$a$$.
Since $$b$$ is also co-prime with $$a$$, it naturally follows that $$(k_i - k_j)b$$ is co-prime with $$a$$.

<!-- TODO: prove the statement below -->
For each $$0 \leq r < a$$, the smallest non-negative element of the residue class $$\lbrace ka + r \rbrace$$ must be in $$B$$, **need to show how**.
This means that $$(a-1)b - a$$ is the greatest non-representable number, which gives us an exact bound

$$
\forall a, b \in \mathbb{N}.
(a, b > 0 \land \gcd(a, b) = 1) \\
\implies
(\not\exists x, y \in \mathbb{N}. ax + by = ab - a - b) \\
\land (\forall n \geq (a-1)(b-1). \exists x, y \in\mathbb{N}. ax + by = n)
$$


<!-- HOL Light has no proof of the |S| = 2 case, add it? -->