---
layout: post
title: Calling Rust from Python via ctypes
date: "2026-08-27 14:36:05 -0400"
---

I needed to test my Rust SHA-1 implementation against a more elaborate set of
test vectors, such as those supplied from NIST's Cryptographic Algorithm
Validation Program (CAVP). Writing a Rust program that parses the CAVP test
vectors and runs my implementation against them is feasible but tedious.
Instead, I chose to work with Python's `ctypes` module to load my Rust library,
then parse and execute the test vectors in Python.

PyO3 is a mature project that really streamlines the process of writing an
interface between my Rust code and the Python test harness, but it requires
introducing additional dependencies into my Rust project. Since I want my Rust
project to remain agnostic to the choice of test harness, I chose to not work
with PyO3, but rather export a C-compatible interface in the compiled library.

The first step is to annotate the Rust project to instruct the compiler to
create C-compatible structs and function calling interface. For a SHA-1
implementation, there is one struct and three public APIs in Rust:

```rust
struct Sha1State {
    hash: [u8; 20],
    buf: [u8; 64],
    buflen: usize,
    bitlen: u64,
}

impl Sha1State {
    pub fn init(&mut self) { ... }
    pub fn update(&mut self, buf: &[u8]) { ... }
    pub fn finalize(&mut self, out: &mut [u8]) { ... }
}
```

The Rust compiler might introduce a different memory layout for struct
`Sha1State` from a C compiler, so ensuring C compatibility requires annotating
the struct with `#[repr(C)]`:

```rust
#[repr(C)]
struct Sha1State { ... }
```

A second difference between Rust and C lies in the function signatures. Rust's
borrow checker can check on references `&` and mutable reference `&mut`, but not
on raw pointers used in C. On the other hand, C has no native notion of
immutable/mutable references, only raw pointers. So with a Rust function
declared with `extern "C"`, `&mut self` needs to be replaced with `*mut
Sha1State`.

```rust
pub extern "C" fn Sha1_init(state: *mut Sha1State) {
    let state = unsafe {
        assert!(!state.is_null());
        &mut *state
    };
    state.init();
}
```

Notice that in the snippet above, `state` begins as a raw pointer, but is later
dereferenced and borrowed as a mutable reference. **Dereferencing a raw
pointer** is considered unsafe in Rust, hence why the dereferencing is wrapped
in an `unsafe` block.

The same conversion from Rust-style borrows to C-style raw pointers also applies
to arrays. `&[u8]` actually contains both a pointer to the array and a length
field, so a Rust function with argument `&[u8]` needs to be broken down into a
tuple of `*const u8` and `usize`, which is then re-assembled back in an unsafe
block using `std::slice::from_raw_parts`. Similarly, a Rust function with
argument `&mut [u8]` needs to be broken down into `*mut u8` and `usize`, then
assemble back using `std::slice::from_raw_parts_mut`:

```rust
pub extern "C" fn Sha1_update(state: *mut Sha1State,
                              buf: *const u8,
                              len: usize) {
    let state = unsafe { /* cast *mut Sha1State into &mut Sha1State; */ };
    let buf = unsafe {
        assert!(!buf.is_null());
        std::slice::from_raw_parts(buf, len)
    };
    state.update(buf);
}

pub extern "C" fn Sha1_finalize(state: *mut Sha1State,
                                out: *mut u8,
                                len: usize) {
    let state = unsafe { /* cast *mut Sha1State into &mut Sha1State; */ };
    let out = unsafe {
        assert!(!out.is_null());
        std::slice::from_raw_parts_mut(out, len)
    };
    state.finalize(out);
}
```

Last but not least, every `extern "C"` declaration needs to be decorated with
`#[unsafe(no_mangle)]` so that the compiler does not mangle the name in the
compiled library.

```rust
#[unsafe(no_mangle)]
pub extern "C" fn Sha1_init(...) { ... }

#[unsafe(no_mangle)]
pub extern "C" fn Sha1_update(...) { ... }

#[unsafe(no_mangle)]
pub extern "C" fn Sha1_finalize(...) { ... }
```

If the names are mangled, it will be difficult to access these
functions in Python land. The `no_mangle` attribute is considered unsafe because
without name mangling there is increased risk of symbol name collisions, and it
is up to the developer to make sure that there is no duplication.

Python's `ctypes` module only supports loading dynamic libraries. For the last
step in Rust land, the compiler needs to be told to compile the Rust code into a
C-compatible dynamic library by adding the following section into `Cargo.toml`:

```toml
[lib]
crate-type = ["rlib", "cdylib"]
```

I could verify the output with `cargo build [--release]`, after which I could
see `target/release/<libname>.dylib`. On Linux the dynamic library will likely
have `.so` extension. On Windows it will likely be `.dll`.

Moving on to Python land. The `ctypes` module exports a `cdll.LoadLibrary`
function that takes a path to the dynamic library file and returns a `CDLL`
object with which I can access the functions.

```python
from ctypes import cdll
lib = cdll.LoadLibrary("target/release/libtoyssl.dylib")
lib.Sha1_init  # <_FuncPtr object at 0x1061d57e0>
```

However, before I can call C functions from Python, I need to define the data
structure `Sha1State`, which takes the form of a class that inherits from
`ctypes.Structure`. Within the class I need to define the `_fields_` attribute,
which is a list of tuples `(name, type)`. In our use case, the two array fields
`hash: [u8; 20]` and `buf: [u8; 64]` translate to `(ctypes.c_uint8 * 20)` and
`(ctypes.c_uint8 * 64)` respectively. The two length fields `buflen: usize` and
`bitlen: u64` translate to `c_size_t` and `c_uint64` respectively:

```python
class Sha1State(ctypes.Structure):
    hash_bytes = 20
    _fields_ = [
        ("hash", c_uint8 * 20),
        ("buf", c_uint8 * 64),
        ("buflen", c_size_t),
        ("bitlen", c_uint64),
    ]
```

It is also a good idea to set `argtypes` and `restype` for each of the function
I will later call so that Python can do some type checking and reduce the risk
of memory corruption and/or undefined behaviors. `argtypes` takes a list of
types, and `restype` takes a single type. For a pointer to a struct which I
have already defined the types for, I can wrap it in `ctypes.POINTER`. The same
applies to C arrays, which degenerate to pointers at function call anyway. Note
that `c_char_p` is only for null-terminated C strings, and for binary data, I
have to use `POINTER(c_uint8)`. Last but not least, `None` in Python denotes
`void` in C. Here is the complete specification:

```python
lib.Sha1_init.argtypes = [POINTER(Sha1State)]
lib.Sha1_init.restype = None
lib.Sha1_update.argtypes = [POINTER(Sha1State), POINTER(c_uint8), c_size_t]
lib.Sha1_update.restype = None
# The same types apply to Sha1_finalize
```

To allocate for a `Sha1State` struct, one can instantiate an instance of the
`Sha1State` class in Python. This instance can be directly passed to `Sha1_init`
and other public functions as a pointer to the struct:

```python
state = Sha1State()
lib.Sha1_init(state)
```

Since I typed the argument for `Sha1_update` and `Sha1_finalize` to be a
pointer to `c_uint8`, I cannot directly pass Python's native `bytes` to these
functions. Instead, I have to allocate for a `c_uint8` array with
`c_uint8 * len` and copy into the allocated array with `from_buffer_copy`:

```python
msg = b"abc"
buf = (c_uint8 * len(msg)).from_buffer_copy(msg)
digest = (c_uint8 * Sha1State.hash_bytes)()
lib.Sha1_update(state, buf, len(msg))
lib.Sha1_finalize(state, digest, Sha1State.hash_bytes)
```

Now I have everything I needed to write the test harness. With Python's built-in
`unittest` module I can whip up a small test module that loads the dynamic library
and test my implementation against all CAVP test cases, all without Python
and Rust needing to be aware of each other.

```python
class Sha1State(Structure):
    hash_bytes = 20
    _fields_ = [
        ("hash", c_uint32 * 5),
        ("block", c_uint8 * 64),
        ("block_len", c_size_t),
        ("processed_bits", c_uint64),
    ]


def read_cavp_vectors(path: str) -> list[tuple[int, bytes, bytes]]:
    """Read a CAVP response file, return a list of (msglen, msg, digest). This
    method relies on specific formatting from the CAVP response file:

    Len = 0
    Msg = 00
    MD = da39a3ee5e6b4b0d3255bfef95601890afd80709
    """
    with open(path) as f:
        data = f.readlines()
    cases = []
    for i, line in enumerate(data):
        if not line.startswith("Len = "):
            continue
        msglen = int(line.split()[2]) // 8
        msg = bytes.fromhex(data[i + 1].split()[2])
        digest = bytes.fromhex(data[i + 2].split()[2])
        if not (msglen == 0 and msg == b"\x00"):
            assert msglen == len(msg), f"Expected msglen {msglen}, found {len(msg)}"
        assert (
            len(digest) == Sha1State.hash_bytes
        ), f"Expected digestlen {Sha1State.hash_bytes}, found {len(digest)}"
        cases.append((msglen, msg, digest))
    return cases


class TestSha1(unittest.TestCase):
    def setUp(self):
        self.libtoyssl = cdll.LoadLibrary(str(TOYSSL_DYLIB_PATH))
        self.libtoyssl.Sha1_init.argtypes = [POINTER(Sha1State)]
        self.libtoyssl.Sha1_init.restype = None
        self.libtoyssl.Sha1_update.argtypes = [
            POINTER(Sha1State),
            POINTER(c_uint8),
            c_size_t,
        ]
        self.libtoyssl.Sha1_update.restype = None
        self.libtoyssl.Sha1_finalize.argtypes = [
            POINTER(Sha1State),
            POINTER(c_uint8),
            c_size_t,
        ]
        self.libtoyssl.Sha1_finalize.restype = None
        self.hasher = Sha1State()
        self.hash = (c_uint8 * Sha1State.hash_bytes)()

    def test_cavp(self):
        for test_suite_name in ["Sha1ShortMsg.rsp", "Sha1LongMsg.rsp"]:
            cases = read_cavp_vectors(str(TOYSSL_TEST_DIR / test_suite_name))
            for i, (msglen, msg_, digest) in enumerate(cases):
                msg = (c_uint8 * msglen).from_buffer_copy(msg_)
                with self.subTest(suite=test_suite_name, case_id=i):
                    self.libtoyssl.Sha1_init(self.hasher)
                    self.libtoyssl.Sha1_update(self.hasher, msg, msglen)
                    self.libtoyssl.Sha1_finalize(
                        self.hasher, self.hash, Sha1State.hash_bytes
                    )
                    self.assertEqual(bytes(self.hash), digest)
```

## References

- <https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/secure-hashing>