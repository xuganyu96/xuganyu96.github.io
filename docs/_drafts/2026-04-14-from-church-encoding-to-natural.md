---
layout: post
title:  "EXISTS: from Church encoding to natural definition"
date:   2026-04-14 16:47:45 -0400
categories: miscellaneous
---

Let $$P$$ be some predicate.

$$
\begin{aligned}
& \forall q. (\forall x. P(x) \implies q ) \implies q \\
& \iff (
    (\forall x. P(x) \implies T) \implies T
) \land (
    (\forall x. P(x) \implies F) \implies F
) \\
& \iff T \land (
    (\forall x. P(x) \implies F) \implies F
) \\
& \iff     (\forall x. P(x) \implies F) \implies F \\
& \iff F \lor \lnot(\forall x. P(x) \implies F) \\
& \iff \lnot(\forall x. P(x) \implies F) \\
& \iff \lnot(\forall x. F \lor \lnot P(x)) \\
& \iff \lnot(\forall x. \lnot P(x))
\end{aligned}
$$

With HOL Light, this equivalence can be proved with `MESON`:

```ocaml
let exists_church = `!q. (!x. (P:A->bool) x ==> q) ==> q`;;
let exists_natural = `~(!x. ~(P:A->bool) x)`;;

MESON [] (mk_forall (
    `P:A->bool`,
    mk_comb (
        mk_comb (`(<=>)`, exists_church),
        exists_natural
    )
));;
```