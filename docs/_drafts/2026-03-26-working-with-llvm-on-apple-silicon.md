---
layout: post
title:  "Working with LLVM on Apple Silicon"
date:   2026-03-26 14:18:20 -0400
categories: cryptography
---

MacOS 26.3.1 ships with this clang version:

```
Apple clang version 17.0.0 (clang-1700.6.4.2)
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

Can we cross-compile to `x86_64` on MacOS using Homebrew's clang-18?

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

Now we have `$LIBOQS_DIR/build/src/kem/frodokem/CMakeFiles/frodokem.dir/external/frodo/frodo640aes.c.o`. We can use LLVM object dump to convert it back to human-readable assembly (with caveats).

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

```
eb8: b4000143     	cbz	x3, 0xee0 <_oqs_kem_frodokem_640_aes_ct_select+0x28>
```

