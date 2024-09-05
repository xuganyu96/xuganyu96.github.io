---
layout: post
title:  "Command-line rust notes (2)"
date:   2023-01-28 21:11:00
categories: rust
---

# Integration testing
In the context of a Rust binary project, integration testing refers to the practice of writing tests that check the behavior of the executable from the user's perspective.

Tests are written as Rust code and placed under the `tests` directory. Each test is a function that has the attribute `#[test]`. Tests can report errors through macros that panic upon specified conditions, or through returned `Result` enums:

```rust
type EmptyResult = Result<(), ()>;

#[test]
fn some_good_test() -> EmptyResult {
    return Ok(());
}

#[test]
fn bad_test() -> EmptyResult {
    return Err(());
}
```

At the time of writing this note, I have written integration tests for my implementation of `echo`, `cat`, and `head`. To run tests from a specific file, use the `--test` flag:

```bash
cargo test --test test_echo
```

# Naive test setup and cleanup
While writing integration tests for `cat` and `head`, some "test data" need to be generated and fed into the program. Without using external crates, I've implemented a naive setup/cleanup process that takes advantage of the `Drop` trait:

```rust
type TestResult = Result<(), Box<dyn Error>>;

struct Setup {
    fn run() -> TestResult {
        // Create files...
    }
}

impl Drop for Setup {
    fn drop(&mut self) {
        // Use system calls to delete the files
    }
}

// Note that this contains the test logic, but is not a test itself!
fn test() -> TestResult {
    let _ = Setup::run();

    // ... content fo the test ...

    return Ok(());
}
```

There are two limitations of this implementaton:

1. Setup needs to be run at each test despite the fact that the set of test data are shared across all tests
2. Race conditions between tests when they are parallelized, which forces the use of `--test-threads 1`

# Custom errors
While implementing integration tests for `test_head`, I ran into a need to raise custom error and custom error messages, which motivated me to implement my own Error type.

Custom errors are structs that implement the `Error` trait (which I bring into the scope using `std::error::Error`). To implement the Error trait:

1. The struct must implement both `Debug` and `Display` trait. `Debug` trait can be derived.
2. To implement the `Display` trait, implement the `fmt` method:

```rust
impl Display for TestFailureError {
    fn fmt(&self, f: &mut Formatter) -> FormatResult {
        write!(f, "{}", self.failure_msg)
    }
}
```

Finally, implement the `Error` trait, whose required methods already have default implementation:

```rust
impl Error for TestFailureError {}
```

# Graceful error handling
From reading "Command-line Rust" it seems that crashing a program through a panic is generally frowned upon and should be avoided. Instead, errors should be gracefully handled and propagated up the call stack up to the top level `main()` function:

```rust
use std::process::exit;
// "run" is the actual main set of logic
use crate::lib::run;

/// The top-level main() function is solely responsible for handling and writing
/// errors to stderr
fn main() {
    if let Err(e) = run() {
        eprintln!(e);
        exit(1);
    }
    exit(0);
}
```

# Buffered reader
## Abstracting type parameterization
While implementing `cat` and `head`, we needed to read from files or `stdin`. In addition, the specification of `head` requires that, especially for a large file, only what's needed (instead of the entire file) is read into memory.

This is where `BufReader` is needed:

```rust
let file_handle = File::open("/path/to-file")?;
let file_reader: BufReader<File> = BufReader::new(file_handle);
let stdin_reader: BufReader<Stdin> = BufReader::new(stdin());
```

In the book, a single function is implemented to handle the instantiation of buffered reader for both files and stdin, despite that `BufReader<Stdin>` and `BufReader<File>` have different memory size. To abstract the type parameterization, a `Box` is used:

```rust
fn open(path: &str) -> Result<Box<dyn BufRead>, Box<dyn Error>> {
    ...
}
```

## Read a specified number of bytes
In the implementation of `head`, we need to implement "reading up to `c` number of bytes from the buffered reader". The book used the `BufRead::bytes()` method, but I find this approach not as suitable because this method will take ownership of the buffered reader.

Instead, I used the `BufRead::read()` method and pass it a buffer with `c` bytes of allocated capacity:

```rust
fn read_bytes<T: BufRead>(
    buf_reader: &mut T,
    buffer: &mut String,
    num: usize,
) -> MyResult<usize> {
    let mut bytes: Vec<u8> = vec![0; num];
    let bytes_written = buf_reader.read(&mut bytes)?;
    buffer.push_str(&String::from_utf8_lossy(&bytes));
    return Ok(bytes_written);
}
```
