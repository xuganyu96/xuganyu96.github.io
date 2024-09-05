---
layout: post
title:  "Command-line rust notes (4)"
date:   2023-02-25 20:39:00
categories: rust
---

While I neglected publishing notes through the past two weeks, I managed to keep up with the "one week per chapter" pace and largely finished the `find`, `uniq`, and `cut` programs.

# Useful crates
* `walkdir` for interacting with the file system and for recursively walking a directory. In the `find` implementation, several higher-level structs such as `DirEntry` are used to distinguish regular files, directories, and symbolic links
* `regex` for compiling and matching regular expression.

# The "Write" trait
The `uniq` program needs to write to an output file when an `fileout` argument is provided, and to write to `STDOUT` when the argument is not provided. Rust abstracts out the difference between writing to file and writing to `STDOUT` using the `Write` trait.

Structs that implement the `Write` trait can be used in the `write!` and `writeln!`.

```rust
use std::io::{ self, Write };

fn open_writer(path: &str) -> Result<Box<dyn Write>, Box<dyn Error>> {
    let writer = match path {
        "" => Box::new(io::stdout()),
        _ => {
            let file = File::create(path)?;
            Box::new(file)
        },
    }
    return Ok(writer);
}

fn flush(
    mut writer: Box<dyn Write>,
    buffer: &str
) {
    write!(writer, "{}", buffer);
}

fn main() {
    let writer = Box::new(io::stdout());
    flush(writer, "Hello, world!");
}
```

# Useful methods
## Filter map
The `Iterator` trait provides a `filter_map` method that I found useful when implementing the `cut` program, particularly the function that cuts out select bytes/characters/fields based on the input list of ranges:

```rust
fn cut_bytes(line: &str, range: &Range<usize>) -> String {
    let bytes: Vec<u8> = line.bytes()
        .enumerate()
        .filter_map(|(i, byte)| {
            if range.contains(&i) {
                return Some(byte);
            }
            return None;
        })
        .collect();
    return String::from_utf8_lossy(&bytes).to_string();
}
```

## Map and map error on results
One annoying thing with implementing a single function for building a buffered reader on `STDOUT` and files is handling when `File::open` returns an error. The error itself only contains the OS error message "No such file or directory (os error 2)", but I want to make it more specific by prefixing it with the path that is passed into `File::open`. One relatively straightforward way is to use the `Result::map_err` method that takes `Result<U, E>` and returns `Result<U, F>` using a closure that takes something of type `E` and returns the something of type `F`:

```rust
use std::{
    error::Error,
    fs::File,
    io::{ BufRead, BufReader }
};

fn open(path: &str) -> Result<Box<dyn BufRead>, Box<dyn Error>> {
    return Ok(Box::new(BufReader::new(File::open(path)?)));
}

fn main() {
    let path = "does-not-exist";
    let reader = open(path).map_err(|e| format!("{path}: {e}"));
    
    if let Err(e) = reader {
        println!("{e}");
    }
}
```

Similarly, the `Result::map` method will take `Result<T, E>` and return `Result<U, E>` using a closure that maps types `T` to `U`.