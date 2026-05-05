---
layout: post
title:  "Simple combinatorics questions"
date:   2026-05-05 14:40:21 -0400
categories: miscellaneous
tags: mathematics hol-light
---

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

- Is it true that if positive integers $$a, b$$ are co-prime, then for sufficiently large $$n \geq N$$, there is always **non-negative solution** $$x, y$$ to the equation $$ax + by = n$$? If yes, how can we compute the lower bound $$N$$?
- Does it make sense to generalize to any set of positive integers $$S = \lbrace s_1, \ldots, s_n \rbrace$$?

