---
layout: page
title: Cryptography
---

## Journals

### Oct 26, 2026

Bit-masked buffer equality test implementation:

- Inputs are byte buffers `uint8_t *`, use a `uint8_t diff` to track byte-by-byte
  difference: `diff |= lhs[i] ^ rhs[i]`
- Promote `uint8_t diff` to a signed integer. `int` is guaranteed to be at least
  16-bit wide, though on many modern 64-bit systems, `int` is 32-bit wide
- If the two buffers are equal, then `diff` must be `0`, so the promoted signed integer
  is also `0`. Otherwise, the promoted integer must be positive. We can subtract 1
  from the promoted integer and set its most significant bit to 1 if `diff` is 0 and
  0 if `diff` is not 0
- With signed integer, right shifts are "arithmetic shift", and will preserve the
  most significant bit

```c
/**
 * @brief return 0 if two buffers are identical, else return -1
 */
int ct_eq(uint8_t *a, uint8_t *b, size_t len) {
    int selector = 0;
    for (size_t i = 0; i < len; i++) {
        selector |= a[i] ^ b[i];
    }
    selector = ~((selector - 1) >> (sizeof(selector) * 8 - 1));
    return selector;
}
```

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
