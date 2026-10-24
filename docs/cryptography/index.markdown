---
layout: page
title: Cryptography
---

## Journals

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
