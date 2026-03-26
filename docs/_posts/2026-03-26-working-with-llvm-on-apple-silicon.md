---
layout: post
title:  "Working with LLVM on Apple Silicon"
date:   2026-03-26 14:18:20 -0400
categories: cryptography
---

# Setup
On my MacBook Air M1 with MacOS 26.3.1, `clang --version` returns the following:

```
Apple clang version 21.0.0 (clang-2100.0.123.102)
Target: arm64-apple-darwin25.3.0
Thread model: posix
InstalledDir: /Library/Developer/CommandLineTools/usr/bin
```

To investigate compiler optimization we need different version:

```bash
brew search llvm
brew install llvm@18
brew info llvm@18
```

I want to investigate whether compiler optimization will introduce branching-on-secret for the following function:

```c
void ct_select(uint8_t *r, const uint8_t *a, const uint8_t *b, size_t len, int8_t selector) 
{ // Select one of the two input arrays to be moved to r
  // If (selector == 0) then load r with a, else if (selector == -1) load r with b
    OQS_MEM_BLACK_BOX(selector);
    for (size_t i = 0; i < len; i++) {
        r[i] = (~selector & a[i]) | (selector & b[i]);
    }
}
```

Build the project:

```bash
# from $LIBOQS_DIR/build
cmake -GNinja \
    -DCMAKE_C_COMPILER="/opt/homebrew/opt/llvm@18/bin/clang-18" \
    -DOQS_MINIMAL_BUILD="KEM_frodokem_640_aes" \
    -DCMAKE_C_FLAGS="-DOQS_DISABLE_MEM_BLACK_BOX" \
    -DCMAKE_BUILD_TYPE="MinSizeRel" \
    ..
ninja
```

Now we have `$LIBOQS_DIR/build/src/kem/frodokem/CMakeFiles/frodokem.dir/external/frodo/frodo640aes.c.o`. We can use LLVM object dump to convert it back to human-readable assembly.

```bash
/opt/homebrew/opt/llvm@18/bin/llvm-objdump -d \
    src/kem/frodokem/CMakeFiles/frodokem.dir/external/frodo/frodo640aes.c.o \
    > frodo640aes.c.o.S
```

Use a text editor to inspect `frodo640aes.c.o.S`. Search for `ct_select`. Get the following relevant section:

```asm
0000000000000eb8 <_oqs_kem_frodokem_640_aes_ct_select>:
     eb8: b4000143     	cbz	x3, 0xee0 <_oqs_kem_frodokem_640_aes_ct_select+0x28>
     ebc: 2a2403e8     	mvn	w8, w4
     ec0: 38401429     	ldrb	w9, [x1], #0x1
     ec4: 3840144a     	ldrb	w10, [x2], #0x1
     ec8: 0a080129     	and	w9, w9, w8
     ecc: 0a04014a     	and	w10, w10, w4
     ed0: 2a090149     	orr	w9, w10, w9
     ed4: 38001409     	strb	w9, [x0], #0x1
     ed8: f1000463     	subs	x3, x3, #0x1
     edc: 54ffff21     	b.ne	0xec0 <_oqs_kem_frodokem_640_aes_ct_select+0x8>
     ee0: d65f03c0     	ret
```

Let's read this line by line.

# Analysis
## eb8: CBZ x3, 0xee0
```
eb8: b4000143     	cbz	x3, 0xee0 <_oqs_kem_frodokem_640_aes_ct_select+0x28>
```

[`cbz <rn> <label>`](https://developer.arm.com/documentation/dui0473/m/arm-and-thumb-instructions/cbz-and-cbnz) is "**c**ompare and **b**ranch on **z**ero". `rn` is the register holding the operand. `label` is the branch destination.

`x3` is a general-purpose register. According to [ARM Procedure Call Standard](https://github.com/ARM-software/abi-aa/releases/download/2025Q4/aapcs64.pdf), on 64-bit ARM, there are 31 general purpose registers, each with a width of 64 bits. In a 64-bit context, they are referred to by `x0` through `x30`; in a 32-bit context, they are referred to by `w0` through `w30`. The first eight (indexed 0 through 7) are used for parameter and results in procedure calls.

Recall the function signature of `ct_select`:

```c
void ct_select(uint8_t *dst, const uint8_t *lhs, const uint8_t *rhs, size_t len,
               int8_t selector);
```

`x3` correspond to the `size_t len`, so this instruction says "if `len` is 0,
then skip to label `0xee0`, which is the `ret` instruction. This makes sense: 
if `len == 0`, then nothing is done, so skip directly to return.

## ebc: MVN w8, w4
`MVN <rd> <op2>` is called "**M**ove **N**ot". It takes the value from `<op2>`
perform a bitwise logical NOT, and store into `<rd>`. `rd` has to be a register
, while `op2` is a [flexible second operand](https://developer.arm.com/documentation/dui0473/m/arm-and-thumb-instructions/flexible-second-operand--operand2-).

From the function signature we know that `w4` holds the value for `int8_t selector` 
(since `selector` is only 8-bit in length, using 32-bit context is reasonable).
FrodoKEM's implementation guarantees `selector` to be either `0xFF` or `0x00`:

```c
OQS_STATUS crypto_kem_dec(unsigned char *ss, const unsigned char *ct,
                          const unsigned char *sk) { /* ... */
    // Needs to avoid branching on secret data using constant-time implementation.
    int8_t selector = ct_verify(Bp, BBp, PARAMS_N*PARAMS_NBAR) 
                      | ct_verify(C, CC, PARAMS_NBAR*PARAMS_NBAR);
    // If (selector == 0) then load k' to do ss = F(ct || k'), else if 
    // (selector == -1) load s to do ss = F(ct || s)
    ct_select((uint8_t*)Fin_k, (uint8_t*)kprime, (uint8_t*)sk_s, CRYPTO_BYTES,
              selector);
    /* ... */
}
```

So `w8` holds the logical opposite of `selector` and serves as the opposite mask.

## Loop body
[`LDR <rt>, [<rn>], #offset`](https://developer.arm.com/documentation/dui0473/m/arm-and-thumb-instructions/ldr--immediate-offset-) stands for "**L**oad **R**egister".

By default `LDR` loads a word (in 64-bit ARM a word is 32-bit wide). `LDRB` is a
special case where `B` stands for unsigned byte. Because `B` is unsigned, the
extended bits are set to 0. There is also `LDRSB`, where `SB` stands for signed
byte, in which case the extended bits are set to the sign bit.

There are many possible syntaxes for `LDR`. The one used here means "load the
word (or unsigned byte) from the memory address stored at register `rn` into
register `rt`, **then** increment `rn` by the literal value of `offset`". This
is called "post-indexing". The counterpart is "pre-indexing", with a syntax of
`[<rn> #offset]`, which means to update the register **before** the accessing
the value.

In `ct_select`, `x1` and `x2` respectively denote the LHS and RHS. If `selector`
is `0x00`, the LHS is selected, else the RHS is selected.

We can now look at the body of the loop:

```asm
     ec0: 38401429     	ldrb	w9, [x1], #0x1
     ec4: 3840144a     	ldrb	w10, [x2], #0x1
     ec8: 0a080129     	and	w9, w9, w8
     ecc: 0a04014a     	and	w10, w10, w4
     ed0: 2a090149     	orr	w9, w10, w9
     ed4: 38001409     	strb	w9, [x0], #0x1
     ed8: f1000463     	subs	x3, x3, #0x1
     edc: 54ffff21     	b.ne	0xec0 <_oqs_kem_frodokem_640_aes_ct_select+0x8>
```

This is a very literal translation of the following C code:

```c
// w9, w10 registers are used as local variables
uint8_t w9, w10;
do {
    // LDR w9, [x1], #0x1
    w9 = *lhs;
    lhs += 1;
    // LDR w10, [x2], #0x1
    w10 = *rhs;
    rhs += 1;
    // AND w9, w9, w8
    w9 = w9 & (~selector);
    // AND w10, w10, w4
    w10 = w10 & selector;
    // ORR w9, w10, w9
    w9 = w10 | w9;
    // STRB w9, [x0], #0x1
    *dst = w9;
    dst += 1;
    // SUBS x3, x3, #0x1
    len -= 1;
} while (
    // B.NE 0xec0
    len != 0
)
```

Note that because at `eb8` the `CBZ` instruction already makes sure that `len`
is greater than 0, it is safe to do a loop body first before checking `len`.
If `len` is 0, then the next instruction `ret` is to return. This function does
not return anything.

# Conclusion
A very literal translation of the C code. It does not seem to branch on secret
(in this context we specifically refer to `selector`).