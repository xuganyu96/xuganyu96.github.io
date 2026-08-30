---
layout: post
title: "Fuzzing my SHA-1 implementation"
date: "2026-08-30 16:59:58 -0400"
---

```
OS: macOS Tahoe 26.6.2 (25G83) arm64
Host: MacBook Air (M1, 2020)
Kernel: Darwin 25.6.0
Uptime: 1 day, 5 hours, 45 mins
Packages: 229 (brew)
Shell: zsh 5.9
Terminal: tmux 3.7c
CPU: Apple M1 (4+4) @ 3.20 GHz
GPU: Apple M1 (8) [Integrated]
Memory: 7.02 GiB / 8.00 GiB (88%)
```

Libfuzzer on Rust requires nightly build:

```bash
rustup default  # print the current toolchain
rustup default nightly  # switch default toolchain to nightly
rustup default stable  # switch default toolchain to stable
```

Install the fuzzer:

```bash
cargo install cargo-fuzz
cargo uninstall cargo-fuzz
```

Start with initializing a fuzz target:

```bash
cargo fuzz init
```

The `init` command generated a sub-project under the `fuzz/` directory with its
own `Cargo.toml` and `fuzz_targets/`. Each target under `fuzz_targets` should
perform fuzzing on one crate. Use `cargo fuzz list` to list all fuzz targets.
The initial fuzz target looks like this:

```rust
#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    /* ... */
});
```

I can fill in with some initial examples where we fuzz the input to the `update`
and the `hash` API:

```rust
fuzz_target!(|data: &[u8]| {
    let mut hasher = toyssl::Sha1_new();
    let mut digest = [0u8; toyssl::Sha1State::DIGEST_BYTES];
    hasher.init();
    hasher.update(data);
    hasher.finalize(&mut digest);

    toyssl::Sha1State::hash(data, &mut digest);
});
```

The default fuzz target name `fuzz_target_1` was rather unhelpful. I renamed it
to `fuzz_sha1` in `fuzz/Cargo.toml`, and renamed the file
`fuzz/fuzz_targets/fuzz_target_1.rs` accordingly. I can run the fuzz test with

```bash
cargo fuzz run fuzz_sha1
```

A fuzz test continuously generates pseudorandom inputs to feed into the test
target. At this point, the fuzz test is rather meaningless because a hash
function almost never crashes and there is not much branching to test against.
Here are a few additions that make this fuzz test more meaningful:

- [ ] Compare against some reference implementation
- [ ] Check against specific input lengths
