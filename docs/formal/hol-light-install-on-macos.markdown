---
layout: page
title: Install HOL Light
---

Now a convenience script:

```bash
curl -fsSL https://xuganyu96.github.io/assets/install-hol.sh | bash
```


s2n-bignum requires the latest HOL Light from source ([arghh](https://github.com/awslabs/s2n-bignum/blob/c403fb04f45ed488b79c767fd9e83e60f439cb44/README.md?plain=1#L331)).

```bash
# Create new switch
opam switch create hol-light-latest 5.4.0
opam switch hol-light-latest
eval $(opam env)
which ocaml  # should return ~/.opam/hol-light-latest/bin/ocaml

# Install dependencies: zarith, ledit, and camlp5
opam update
opam install -y zarith ledit
opam pin -y add camlp5 8.04.00
opam list
export CAMLP5LIB="$HOME/.opam/hol-light-latest/lib/camlp5"

# Build HOL Light
git clone git@github.com:jrh13/hol-light.git && cd hol-light
HOLLIGHT_USE_MODULE=1 make
./hol.sh

# Export HOLLIGHT_DIR in shell, add hol.sh to path
export HOLLIGHT_DIR="/path/to/hol-light"
export PATH="$PATH:$HOLLIGHT_DIR"
```
