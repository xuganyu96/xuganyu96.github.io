---
layout: page
title: Cryptography
---

## Journals

### Oct 27, 2026

What happens if I compile two object files where each object file has a symbol with
the same name but does different thing?

```c
// liblucky.h
int get_lucky();

// lucky1.c
int get_lucky() {
    return 1;
}

// lucky2.c
int get_lucky() {
    return 2;
}
```

Compile into static library and inspect.

```bash
cc -g -c lucky1.c lucky2.c
ar -rcs liblucky.a lucky1.o lucky2.o
objdump -d liblucky.a
```

The archive (static library) contains both symbols:

```asm
liblucky.a(lucky1.o):	file format mach-o arm64

Disassembly of section __TEXT,__text:

0000000000000000 <ltmp0>:
       0: 52800020     	mov	w0, #0x1                ; =1
       4: d65f03c0     	ret

liblucky.a(lucky2.o):	file format mach-o arm64

Disassembly of section __TEXT,__text:

0000000000000000 <ltmp0>:
       0: 52800040     	mov	w0, #0x2                ; =2
       4: d65f03c0     	ret
```

Add a binary and link against it:

```c
// main.c
#include <stdio.h>
#include "liblucky.h"

int main(void) {
    printf("Lucky number %d\n", get_lucky());
    return 0;
}
```

```bash
cc -g -o main.out main.c liblucky.a
objdump -d main.out
```

```asm
main.out:	file format mach-o arm64

Disassembly of section __TEXT,__text:

0000000100000460 <_main>:
100000460: d10083ff    	sub	sp, sp, #0x20
100000464: a9017bfd    	stp	x29, x30, [sp, #0x10]
100000468: 910043fd    	add	x29, sp, #0x10
10000046c: 52800008    	mov	w8, #0x0                ; =0
100000470: b9000be8    	str	w8, [sp, #0x8]
100000474: b81fc3bf    	stur	wzr, [x29, #-0x4]
100000478: 9400000b    	bl	0x1000004a4 <_get_lucky>
10000047c: 910003e9    	mov	x9, sp
100000480: aa0003e8    	mov	x8, x0
100000484: f9000128    	str	x8, [x9]
100000488: 90000000    	adrp	x0, 0x100000000 <_printf+0x100000000>
10000048c: 9112e000    	add	x0, x0, #0x4b8
100000490: 94000007    	bl	0x1000004ac <_printf+0x1000004ac>
100000494: b9400be0    	ldr	w0, [sp, #0x8]
100000498: a9417bfd    	ldp	x29, x30, [sp, #0x10]
10000049c: 910083ff    	add	sp, sp, #0x20
1000004a0: d65f03c0    	ret

00000001000004a4 <_get_lucky>:
1000004a4: 52800020    	mov	w0, #0x1                ; =1
1000004a8: d65f03c0    	ret

Disassembly of section __TEXT,__stubs:

00000001000004ac <__stubs>:
1000004ac: 90000030    	adrp	x16, 0x100004000 <_printf+0x100004000>
1000004b0: f9400210    	ldr	x16, [x16]
1000004b4: d61f0200    	br	x16
```

I guess that the first matching symbol is used and the other one is discarded. If
true, then swapping the order will get `main` to print 2:

```bash
rm liblucky.a
ar -rcs liblucky.a lucky2.o lucky1.o
cc -g -o main.out main.c liblucky.a
```

Hence the need for namespacing.

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
