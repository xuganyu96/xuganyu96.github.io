---
layout: page
title: HOL Light notes
---

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
