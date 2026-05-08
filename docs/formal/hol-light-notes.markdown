---
layout: page
title: HOL Light notes
---

- [Trivial example](#trivial-example)
- [Simple example](#simple-example)
- [Simple non-linear real inequality](#simple-non-linear-real-inequality)
- [Linear sum](#linear-sum)
- [Even numbers](#even-numbers)
- [Bug puzzle](#bug-puzzle)
- [Mutex](#mutex)


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

# Even numbers

```ocaml
(* Inductive definition *)
let EVEN_RULES, EVEN_INDUCT, EVEN_CASES = new_inductive_definition 
    `E 0 /\ !n. E n ==> E (n + 2)`;;

let goal = `!n. E n ==> ?k. n = 2 * k`;;

g goal;;
e (MATCH_MP_TAC EVEN_INDUCT THEN REPEAT STRIP_TAC);;

(* The base case *)
e (EXISTS_TAC `0` THEN ARITH_TAC);;

(* The inductive step *)
e (ASM_REWRITE_TAC [] THEN EXISTS_TAC `k + 1` THEN ARITH_TAC);;

top_thm();;
```

# Bug puzzle

```ocaml
(* The bugs puzzle *)
prioritize_real();;

(* The three bugs can only move one at a time and the moving bug can only move
   along the line parallel to the line joining the other two bugs
 *)
let rotations = [
    (`xb:real`, `xa:real`); (`yb:real`,`ya:real`);
    (`xc:real`, `xb:real`); (`yc:real`,`yb:real`);
    (`xa:real`, `xc:real`); (`ya:real`,`yc:real`);
    (`xb':real`, `xa':real`); (`yb':real`,`ya':real`);
    (`xc':real`, `xb':real`); (`yc':real`,`yb':real`);
    (`xa':real`, `xc':real`); (`ya':real`,`yc':real`);
];;
let a_move = `
    ?k:real.
    (xa' - xa) = k * (xc - xb) 
    /\ (ya' - ya) = k * (yc - yb)
    /\ yb' = yb /\ xb' = xb
    /\ yc' = yc /\ xc' = xc
`;;
let b_move = subst rotations a_move;;
let c_move = subst rotations b_move;;
let one_move = mk_disj (mk_disj (a_move,b_move), c_move);;
let move_def_lhs = `
    (move:real#real#real#real#real#real->real#real#real#real#real#real->bool)
        (xa,ya,xb,yb,xc,yc)
        (xa',ya',xb',yb',xc',yc')`;;

let MOVE_DEF = new_definition (mk_eq (move_def_lhs,one_move));;

let REACH_RULES, REACH_INDUCT, REACH_CASES = new_inductive_definition `
    (!p. reach p p)
    /\ (!p q r. reach p q /\ move q r ==> reach p r)
`;;

(* oriented area: the determinant of [b - a; c - a] *)
let SIGNEDAREA_DEF = new_definition `
    signedarea (xa,ya,xb,yb,xc,yc:real) 
    = (xb - xa) * (yc - ya) - (yb - ya) * (xc - xa)`;;

let invariant = `!p q. move p q ==> (signedarea p = signedarea q)`;;

g invariant;;
(* NOTE:
    I tried to begin with (REPEAT STRIP_TAC), which produced the following:
            `{move p q} ?- signedarea p = signedarea q`
    At which point (RULE_ASSUM_TAC (REWRITE_RULE [FORALL_PAIR_THM; ...])) and
    (REWRITE_TAC [FORALL_PAIR_THM; ...]) will not rewrite move nor signedarea
    but the steps below works.
 *)
e (REWRITE_TAC [FORALL_PAIR_THM; MOVE_DEF; SIGNEDAREA_DEF]);;
e (CONV_TAC REAL_RING);;
let MOVE_INVARIANT = top_thm();;

g `!p q. reach p q ==> (signedarea p = signedarea q)`;;
e (MATCH_MP_TAC REACH_INDUCT);;
e (MESON_TAC [MOVE_INVARIANT]);;
let REACH_INVARIANT = top_thm();;

(* Starting at (0,0), (0,3), (3,0):
   It is impossible to reach (0,0), (3,0), (0,3)
   It is impossible to reach (1,2), (2,5), (-2,3)
*)
g `~(reach (&0,&0,&0,&3,&3,&0) (&0,&0,&3,&0,&0,&3))`;;
e (REPEAT STRIP_TAC);;

(* TODO: pay special attention to this *)
e (FIRST_ASSUM (MP_TAC o (MATCH_MP REACH_INVARIANT)));;
e (REWRITE_TAC [SIGNEDAREA_DEF] THEN REAL_ARITH_TAC);;
let UNREACHABLE_1 = top_thm();;

g `~(
    reach (&0,&0,&0,&3,&3,&0) (&1,&2,&2,&5,-- &2,&3)
    \/ reach (&0,&0,&0,&3,&3,&0) (&1,&2,-- &2,&3,&2,&5)
    \/ reach (&0,&0,&0,&3,&3,&0) (&2,&5,&1,&2,-- &2,&3)
    \/ reach (&0,&0,&0,&3,&3,&0) (&2,&5,-- &2,&3,&1,&2)
    \/ reach (&0,&0,&0,&3,&3,&0) (-- &2,&3,&1,&2,&2,&5)
    \/ reach (&0,&0,&0,&3,&3,&0) (-- &2,&3,&2,&5,&1,&2)
)`;;
e (
    REPEAT STRIP_TAC
        THEN FIRST_ASSUM (MP_TAC o (MATCH_MP REACH_INVARIANT))
        THEN REWRITE_TAC [SIGNEDAREA_DEF]
        THEN REAL_ARITH_TAC
);;
let UNREACHABLE_2 = top_thm();;
```

# Mutex

```ocaml
(* TODO: lock does not necessarily have to begin at 0, but not beginning at 0
   will cause a deadlock
*)
let INIT_DEF = new_definition `init (pc1,pc2,lock) = (pc1 = 10 /\ pc2 = 10 /\ lock = 0)`;;
let MUTEX_DEF = new_definition `mutex (pc1,pc2,lock:num) = (pc1 = 10 \/ pc2 = 10)`;;

(* the set of possible state transitions *)
let STEP_DEF = new_definition `
    step (pc1,pc2,lock) (pc1',pc2',lock') = (
    (pc1 = 10 /\ lock = 1 /\ pc1' = pc1 /\ pc2' = pc2 /\ lock' = lock)
    \/ (pc1 = 10 /\ lock = 0 /\ pc1' = 20 /\ pc2' = pc2 /\ lock' = SUC lock)
    \/ (pc1 = 20 /\ pc1' = 10 /\ pc2' = pc2 /\ lock' = PRE lock)
    \/ (pc2 = 10 /\ lock = 1 /\ pc1' = pc1 /\ pc2' = pc2 /\ lock' = lock)
    \/ (pc2 = 10 /\ lock = 0 /\ pc1' = pc1 /\ pc2' = 20 /\ lock' = SUC lock)
    \/ (pc2 = 20 /\ pc1' = pc1 /\ pc2' = 10 /\ lock' = PRE lock))
`;;

(* q is reachable from p by steps *)
let REACH_RULES,REACH_INDUCT,REACH_CASES = new_inductive_definition 
    `(!p. reach p p) /\ (!p q r. reach p q /\ step q r ==> reach p r)`;;

(* the thing we actually want to prove *)
let goal = `!p q. init p /\ reach p q ==> mutex q`;;

(* We actually need a stronger invariant than mutex itself.

   The statement `step p q /\ mutex p ==> mutex q` is actually false. Here is
   a counter example:
   Starting state is (pc1=10, pc2=20, lock=0) and advancing on routine 1. After
   executing label 10 on routine 1, the state becomes (pc1=20, pc2=20, lock=1),
   so despite starting state satisfying mutex, final state fails mutex.

   This counter example does not disprove the final result, however, because
   the starting state itself is invalid: if pc2=20, then lock cannot be free.
   The constraint "if one of pc1 and pc2 is at critical section implies lock
   being held" is not encoded into the definition of mutex, hence we need a
   stronger invariant:
*)
let LOCKED_DEF = new_definition 
    `locked (pc1,pc2,lock) 
    = (pc1=10 /\ pc2=10 \/ pc1=10 /\ lock=1 \/ pc2=10 /\ lock=1)`;;
let step_invariant = `!p q. step p q ==> locked p ==> locked q`;;
g step_invariant;;
e (REWRITE_TAC [FORALL_PAIR_THM; STEP_DEF; LOCKED_DEF]);;
e (CONV_TAC ARITH_RULE);; (* this will take a second *)
let STEP_INVARIANT = top_thm();;

let reach_invariant = `!p q. reach p q ==> locked p ==> locked q`;;
g reach_invariant;;
e (MATCH_MP_TAC REACH_INDUCT);;

(*
`(forall p. locked p ==> locked p) /\
 (forall p q r.
      (locked p ==> locked q) /\ step q r ==> locked p ==> locked r)`
*)

e CONJ_TAC;;
(* the first subgoal `forall p. locked p ==> locked p` is trivial *)
e (MESON_TAC []);;

(* the second subgoal is
   `forall p q r. (locked p ==> locked q) /\ step q r ==> locked p ==> locked r`
*)
e (MESON_TAC [STEP_INVARIANT]);;
let REACH_INVARIANT = top_thm();;

(* Prove that the initial condition satisfies LOCKED *)
let INIT_LOCKED = prove(
    `!p. init p ==> locked p`,
    REWRITE_TAC [INIT_DEF; LOCKED_DEF; FORALL_PAIR_THM] 
    THEN MESON_TAC []
);;

g goal;;
e (REWRITE_TAC [INIT_LOCKED; REACH_INVARIANT; MUTEX_DEF; FORALL_PAIR_THM]);;
e (REPEAT STRIP_TAC);;
e (FIRST_ASSUM (MP_TAC o (MATCH_MP REACH_INVARIANT)));;
e (FIRST_ASSUM (MP_TAC o (MATCH_MP INIT_LOCKED)));;
e (MESON_TAC [LOCKED_DEF]);;
top_thm();;
```
