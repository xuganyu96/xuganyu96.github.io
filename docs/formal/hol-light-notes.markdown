---
layout: page
title: HOL Light notes
---

- [Trivial example](#trivial-example)
- [Simple example](#simple-example)
- [Simple non-linear real inequality](#simple-non-linear-real-inequality)
- [Linear sum](#linear-sum)


# Trivial example

```ocaml
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

```ocaml
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

```ocaml
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

```ocaml
(* natural number sum: (A->bool)->(A->num)->num *)
let summation = `nsum`;;
(* natural number range: num->bool *)
let range = `1..2`;;

(* NOTE:
   Pay special attention to DIV because it is a truncating division.
               n * (n + 1) DIV 2
   and
               (n * (n + 1)) DIV 2
   are actually algebraically different
 *)
let root = `!n:num. nsum (1..n) (\i. i) = (n * (n + 1)) DIV 2`;;

g root;;

e INDUCT_TAC;;

search [`SUC n`; `nsum`];;

(* The search returns NSUM_CLAUSES_NUMSEG, NSUM_CLAUSES_NUMSEG_LE,
   NSUM_CLAUSES_NUMSEG_LT *)
string_of_thm NSUM_CLAUSES_NUMSEG;;

(* This handles the base case *)
e (REWRITE_TAC [NSUM_CLAUSES_NUMSEG]);;
e ARITH_TAC;;

(*  for the inductive step, applying this rewrite produces this subgoal:
    {
        nsum (1..n) (\i. i) = (n * (n + 1)) DIV 2
    }
    |-? (
        if 1 <= SUC n 
            then nsum (1..n) (\i. i) + SUC n) 
            else nsum (1..n) (\i. i)
        = SUC n * (SUC n + 1) DIV 2
    )
 *)
e (REWRITE_TAC [NSUM_CLAUSES_NUMSEG]);;

(*  Since 1 <= SUC n is always true, we can remove the "else" clause in the LHS
 *)
e (REWRITE_TAC [ARITH_RULE `1 <= SUC n`]);;

(*  goalstack:

      0 [`nsum (1..n) (\i. i) = n * (n + 1) DIV 2`]

    `nsum (1..n) (\i. i) + SUC n = SUC n * (SUC n + 1) DIV 2`
 *)

(* rewrite goal with assumption *)
e (ASM_REWRITE_TAC []);;

(*  goalstack:

      0 [`nsum (1..n) (\i. i) = n * (n + 1) DIV 2`]

    `n * (n + 1) DIV 2 + SUC n = SUC n * (SUC n + 1) DIV 2`

    At this point the goal itself already contains everything it needs, but
    ARITH_RULE cannot handle the goal yet.
 *)
e ARITH_TAC;;
top_thm();;

(* TODO: this can be simplified *)
prove (
    `!n:num. nsum (1..n) (\i. i) = (n * (n + 1)) DIV 2`,
    INDUCT_TAC
    THEN REWRITE_TAC [NSUM_CLAUSES_NUMSEG]
    THENL [
        ARITH_TAC;
        ASM_REWRITE_TAC [ARITH_RULE `1 <= SUC n`]
        THEN ARITH_TAC;
    ]
);;
```
