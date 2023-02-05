---
layout: post
title:  "Command-line rust notes (3)"
date:   2023-02-04 20:46:00
categories: rust
---

# Conflicting command-line arguments
In some versions of the `wc` program, the flags for counting bytes `-c` and for counting characters `-m` cannot be used together, or an error message will be displayed. The crate for parsing command line arguments `clap` has the option to set two command-line arguments as conflicting using the attribute `conflicts_with`:

```rust
#[derive(Parser, Debug)]
struct Arg {
    /// The number of words in each input file is written to the standard
    /// output
    #[arg(short = 'w')]
    words: bool,

    /// The number of bytes in each input file is written to the standard
    /// output. This will conflict with the usage of "-m" option
    #[arg(short = 'c')]
    #[arg(conflicts_with("chars"))]
    bytes: bool,

    /// The number of characters in each input file is written to the standard
    /// output. If the current locale does not support multibyte characters,
    /// then this is equivalent to the "-c" option. This will conflict with
    /// the usage of the "-c" option
    #[arg(short = 'm')]
    chars: bool,

    /// The number of lines in each input file is written to the standard
    /// output
    #[arg(short = 'l')]
    lines: bool,

    files: Vec<String>,
}
```

When the two conflicting arguments are used in the same call, the parser will throw an error that can then be propagated onto the top level `main()` function. The error message looks something like this:

```
error: the argument '-c' cannot be used with '-m'
```

# Mock buffered reader
The `std::io::Cursor` struct "wraps an in-memory buffer" and implements the `BufRead` trait. As a result, it can be used to quickly mock up a buffered reader for testing functions that take `BufRead`.

In my `wc` implementation, I used it to test the instantiation of word count info from buffered readers:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    #[test]
    fn create_word_cnt_info() {
        let test_str = "锟斤拷\n锘锘锘\n烫烫烫\n屯屯屯\n";
        let mut reader = Cursor::new(test_str);
        let wcinfo = WordCountInfo::from_read("", &mut reader).unwrap();

        assert_eq!(wcinfo.line_cnt, 4);
        assert_eq!(wcinfo.word_cnt, 4);
        assert_eq!(wcinfo.byte_cnt, 40);
        assert_eq!(wcinfo.char_cnt, 16);
    }
}
```