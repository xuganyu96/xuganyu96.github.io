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

```ocaml
prove (
    `n <= 2 /\ n >= 2 ==> f(2, 2) + n < f(n, n) + 7`,
    (REWRITE_TAC [LE_ANTISYM; GE])
    THEN DISCH_TAC
    THEN (ASM_REWRITE_TAC [])
    THEN (REWRITE_TAC [LT_ADD_LCANCEL])
    THEN ARITH_TAC
);;
```
