---
layout: post
title:  "Setting up HOL Light on MacOS"
date:   2026-04-24 12:54:48 -0400
categories: cryptography
---

> [*reference*](https://hol-light.github.io/)

An easy way to get OCaml on MacOS is with OCaml Package Manager (OPAM).
OPAM can be installed with Homebrew:

```bash
brew install opam
brew info opam
```

On a fresh install, OPAM needs to initialize itself with `opam init`.
By default, OPAM works exclusively within the `~/.opam` directories, which can be nuked to start fresh.

```bash
rm -rf ~/.opam
opam init
```

At initialization, OPAM will add an initialization script to `~/.zshrc` to save the need to run `eval $(opam env)` every time I need to access OPAM installation:

```bash
# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/Users/ganyuxu/.opam/opam-init/init.zsh' ]] || source '/Users/ganyuxu/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration
```

In my instance, the initialization process installed the following:

```
<><> Creating initial switch 'default' (invariant ["ocaml" {>= "4.05.0"}] - initially with ocaml-base-compiler)

<><> Installing new switch packages <><><><><><><><><><><><><><><><><><><><>  🐫
Switch invariant: ["ocaml" {>= "4.05.0"}]

<><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><>  🐫
∗ installed base-bigarray.base
∗ installed base-threads.base
∗ installed base-unix.base
∗ installed ocaml-options-vanilla.1
∗ installed ocaml-compiler.5.4.1
∗ installed ocaml-base-compiler.5.4.1
∗ installed ocaml-config.3
∗ installed ocaml.5.4.1
∗ installed base-domains.base
∗ installed base-effects.base
∗ installed base-nnp.base
```

Open another terminal and print `PATH`: `~/.opam/default/bin` was added to path.
Check that the toplevel is available with `ocaml --version`:

```
The OCaml toplevel, version 5.4.1
```

OPAM can function like an environment manager (think `pyenv` or `rbenv`).
Use `opam switch create [name] <package-or-version>` to create a new environment with the specified compiler.
The [3.1.0 release of HOL Light](https://github.com/jrh13/hol-light/tree/Release-3.1.0) is tested against OCaml 5.2.0, so that's what I will create:

```bash
opam switch create hol-light-3.1 5.2.0
```

This created a subdirectory `~/.opam/hol-light-3.1`. Under `~/.opam/hol-light-3.1/bin`, the `ocaml` binary reports version `5.2.0` as intended.
We can switch between the environments:

```bash
opam switch <default|hol-light-3.1>
eval $(opam env)
# under hol-light-3.1 it should be 5.2.0
ocaml --version
```

Under the `hol-light-3.1` switch, HOL Light can be installed using OPAM:

```bash
opam install hol_light.3.1.0 hol_light_module
```

After running `hol.sh`, you can load other `.ml` proofs with:

```ocaml
#use "file.ml";;
```
