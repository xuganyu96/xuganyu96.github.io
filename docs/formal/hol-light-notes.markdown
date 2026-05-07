---
layout: page
title: HOL Light notes
---

- [Trivial example](#trivial-example)
- [Simple example](#simple-example)
- [Simple non-linear real inequality](#simple-non-linear-real-inequality)
- [Linear sum](#linear-sum)
<!-- TODO: [Even integers](#even-integers) -->
<!-- TODO: [Bug puzzle](#bug-puzzle) -->
<!-- TODO: [Mutex](#mutex) -->


# Trivial example

```
let A_DEF = new_basic_definition `A = T`;;
let B_DEF = new_basic_definition `B = T`;;
let C_DEF = new_basic_definition `C = T`;;

prove (
    `A /\ B /\ C`,
    CONJ_TAC
    THENL [
        (ASSUME_TAC A_DEF)
        THEN (ASM_REWRITE_TAC []);
        CONJ_TAC
        THENL [
            REWRITE_TAC[B_DEF];
            REWRITE_TAC[C_DEF]
        ]
    ]
);;
```

# Simple example

$$
\begin{equation*}
    \forall n f.
    n \le 2 \land n \ge 2
    \implies 
    f(2, 2) + n < f(n, n) + 7
\end{equation*}
$$

```
prove (
    `!n f. (n <= 2 /\  n >= 2) ==> (f(2, 2) + n < f(n, n) + 7)`,
    STRIP_TAC THEN STRIP_TAC
    THEN (REWRITE_TAC [LE_ANTISYM; GE])
    THEN DISCH_TAC
    THEN (ASM_REWRITE_TAC [])
    THEN ARITH_TAC
);;
```

# Simple non-linear real inequality

$$
\forall x, y \in \mathbb{R}.
    0 < xy \implies (0 < x \iff 0 < y)
$$

```
let root = `!x y:real. &0 < x * y ==> (&0 < x <=> &0 < y)`;;
prove (
    root,
    REPEAT STRIP_TAC 
    THEN EQ_TAC 
    THEN STRIP_TAC
    THEN RULE_ASSUM_TAC (ONCE_REWRITE_RULE [REAL_MUL_POS_LT])
    THEN FIRST_X_ASSUM DISJ_CASES_TAC
    THEN ASM_REAL_ARITH_TAC
);;
```

# Linear sum

$$
\forall n \in \mathbb{N}. \sum_{i=1}^n i = \frac{n (n + 1)}{2}
$$

## Formalization
We begin with formalizing the statement.
There are two key ingredients in the formalization: summation and linear range.
HOL Light has a built-in function for expressing summation `nsum: (A->bool)->(A->num)->num`.
From the HOL type we can infer the arguments passed to `nsum`:
- A predicate on set `A`
- A map from elements of `A` into natural numbers

`nsum` works over the natural numbers.
Correspondingly, there are `isum` and `sum`, working over the integers `:int` and the reals `:real` respectively.

A linear range `(a:num)..b` is parsed into a function type `:num->bool`.
However, the range itself has no arithmetic meaning and needs additional theorems to prove meaningful results:

```ocaml
(* this does not work *)
prove (`10 IN (1..10)`, ARITH_TAC);;

(* this works *)
prove (`10 IN (1..10)`, REWRITE_TAC [IN_NUMSEG] THEN ARITH_TAC);;
```

Formalizing the summation term thus looks like this:

```
nsum (1..n) (\i. i)
```

The RHS of the equation involves a `DIV` operator, which demands special attention.
This is because the default `:num` type uses a truncating division that happens to have higher precedence than multiplication.
Therefore, it is necessary to write the RHS with an extra pair of parentheses:

```
(n * (n + 1)) DIV 2
```

Without the extra parentheses `n * (n + 1) DIV 2` is actually `n * ((n + 1) DIV 2)`, which is arithmetically different from what we really mean.

Putting everything together:

```ocaml
let root = `!n. nsum (1..n) (\i. i) = (n * (n + 1)) DIV 2`;;
```

## Proof
This is a classic of inductive proof, which breaks the result into a base case and an inductive step.
HOL Light has a built-in `INDUCT_TAC` which will break a goal with form `!n. P[n]` into two subgoals: the base case `P[n -> 0]` (`n` is substituted with `0`) and the inductive step `P[n] |- P[n -> SUC n]`.
The base case will be the top subgoal in the new goal state.

```
# e INDUCT_TAC;;
val it : goalstack = 2 subgoals (2 total)

  0 [`nsum (1..n) (\i. i) = (n * (n + 1)) DIV 2`]

`nsum (1..SUC n) (\i. i) = (SUC n * (SUC n + 1)) DIV 2`

`nsum (1..0) (\i. i) = (0 * (0 + 1)) DIV 2`
```

The base case is arithmetically straightforward, but `ARITH_RULE` has not concept of summation, so a theorem is needed to rewrite the LHS of the base case:

```ocaml
search [`x..0`; `nsum`];;
```

This search returns a theorem named `NSUM_CLAUSES_NUMSEG`:

```ocaml
|- (forall m. nsum (m..0) f = (if m = 0 then f 0 else 0)) /\
(forall m n.
    nsum (m..SUC n) f =
    (if m <= SUC n then nsum (m..n) f + f (SUC n) else nsum (m..n) f))
```

One of the conjunctive sub-term spells exactly what we need to rewrite the LHS of the base case into 0. The rest can be handled with `ARITH_RULE`.
Now we have the inductive step left.

```
# e (REWRITE_TAC [NSUM_CLAUSES_NUMSEG] THEN ARITH_TAC);;
val it : goalstack = 1 subgoal (1 total)

  0 [`nsum (1..n) (\i. i) = (n * (n + 1)) DIV 2`]

`nsum (1..SUC n) (\i. i) = (SUC n * (SUC n + 1)) DIV 2`
```

Observe that `NSUM_CLAUSES_NUMSEG`'s second conjunctive sub-term matches the syntax of the inductive step, so we can rewrite:

```
# e (REWRITE_TAC [NSUM_CLAUSES_NUMSEG]);;
val it : goalstack = 1 subgoal (1 total)

  0 [`nsum (1..n) (\i. i) = (n * (n + 1)) DIV 2`]

`(if 1 <= SUC n then nsum (1..n) (\i. i) + SUC n else nsum (1..n) (\i. i)) =
 (SUC n * (SUC n + 1)) DIV 2`
```

Notice that `1 <= SUC n` is always true so we can simplify the LHS of this sub-goal with simple arithmetic:

```
# e (REWRITE_TAC [ARITH_RULE `!n. 1 <= SUC n`]);;
val it : goalstack = 1 subgoal (1 total)

  0 [`nsum (1..n) (\i. i) = (n * (n + 1)) DIV 2`]

`nsum (1..n) (\i. i) + SUC n = (SUC n * (SUC n + 1)) DIV 2`
```

We can substitute `nsum (1..n) (\i. i)` with `(n * (n + 1)) DIV 2` using the assumption.
The rest is straightforward arithemtic:

```
# e (ASM_REWRITE_TAC [] THEN ARITH_TAC);;
val it : goalstack = No subgoals
```

We can also take a different route that rewrites the branches of the `if ... then ... else ...` block BEFORE applying arithmetic reasoning.
This route is nice because it calls `ASM_REWRITE_TAC [NSUM_CLAUSES_NUMSEG]` then `ARITH_TAC` just like in the base case, which means that we can package the entire proof very neatly:

```ocaml
prove (
    `!n. nsum (1..n) (\i. i) = (n * (n + 1)) DIV 2`,
    INDUCT_TAC
    THEN ASM_REWRITE_TAC [NSUM_CLAUSES_NUMSEG]
    THEN ARITH_TAC
);;
```

<!-- TODO: sum of squares and sum of cubes -->
