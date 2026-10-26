---
layout: page
title: Cryptography
---

## Journals

### Oct 25, 2026

Here is a snippet from FrodoKEM-640 reference implementation, compiled for ARM64
using Clang-18 with `-Os` optimization:

```asm
cmp     w8, #0x0
csel    x8, x12, x20, lt
ldr     q0, [x8]
```

- `w8` is the lower 32 bits of the 64-bit register `x8`
- `w8` holds the `int selector` output from constant time equality check between
  re-encryption and input ciphertext. It is 0 if two buffers are equal and -1 otherwise
- **TODO**: independently reproduce `int cteq(uint8_t *, uint8_t *, size_t)`

`csel` loads the value in `x12` into `x8` if the condition is true. `lt` denotes
"signed less than", which is true iff `w8` is less than 0. `ldr` denotes "Load Register."
`q0` is 128-bit wide. In FrodoKEM specification, length of implicit rejection
symbol is denoted by $$\text{len}_s$$, which is 128, 192, and 256 bits respectively
for FrodoKEM-640, 976, 1344.

### Oct 24, 2026

In FIPS.197, the most significant bit in a byte is indexed 7. The most significant
bit in the first byte of a byte sequence is the first bit in the byte sequence.

C type `uint8_t arr[4][8]` denotes an array of 4 elements, where each element is
an array of 8 bytes.

With 128-bit AES block, each block is a 4-by-4 byte matrix. Given input byte array
`uint8_t in[16]`, the matrix is laid out as `block[row][col] = in[row + 4 * col]`.

|           | col 0   | col 1   | col 2    | col 3    |
|-----------|---------|---------|----------|----------|
| **row 0** | `in[0]` | `in[4]` | `in[8]`  | `in[12]` |
| **row 1** | `in[1]` | `in[5]` | `in[9]`  | `in[13]` |
| **row 2** | `in[2]` | `in[6]` | `in[10]` | `in[14]` |
| **row 3** | `in[3]` | `in[7]` | `in[11]` | `in[15]` |

Each column is also interpreted as a 32-bit word. FIPS.197 states that

> row index r becomes the index for the four bytes in each word

In other words, row 0 is the most significant byte in the word.

## Appendix
