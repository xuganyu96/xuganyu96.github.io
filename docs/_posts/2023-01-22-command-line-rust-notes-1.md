---
layout: post
title:  "Command-line rust notes (1)"
date:   2023-01-22 20:56:00
categories: rust
---

# Accessing command line arguments
`std::env::args() -> Args` returns an iterators on the command line arguments passed into the binary:

```rust
impl Iterator for Args {
    type Item = String;
    fn next(&mut self) -> Option<String>
}
```

# Channeling standard out and standard error
When running a command line program, standard output goes to channel 1 while standard error goes to channel 2:

```bash
# stdout will be written to ./out and stderr will be written to ./err
some-command ... 1>out 2>err
```

# Parsing command line arguments
`clap` is a crate that can be used declare and parse command line arguments:

```bash
cargo add clap@4.0.32 --features derive
```

1. To declare a CLI schema, bring in the `clap::Parser` trait, then define a struct with the `#[derive(Parser)]` attribute
2. Add attributes like `#[command(...)]` to the argument struct to define metadata for the program. Common options include `authors`, `about`, `long_about`, `version`. They will show up when running with the `-h/--help` and/or `-v/--version` flags. They default to what is written in `Cargo.toml` 
3. For keyword arguments, some common options:
    - `#[arg(short='n', long="number")]` (use characters for the "short" flag)
    - `#[arg(default_value_t=...)]`
4. Positional argument behaviors:
    - `file: String`: a single argument that is required
    - `file: Option<String>`: a single, optional argument
    - `files Vec<String>`: zero or more positional arguments

# Dependencies for testing only
Adding the `--dev` flag in `cargo add` means that the crate will be compiled for testing only. One useful crate is `assert_cmd`, which can be used to run both system binaries and cargo binaries:

```rust
let assert = Command::cargo_bin("mybin")?  // => Result<Command, ...>
    .args(&["-f", "-l"])
    .write_std("Hello, world")
    .assert()  // => assert_cmd::Assert
    .success()
    .try_stdout("some output")?
    .try_stderr("some errors")?
```