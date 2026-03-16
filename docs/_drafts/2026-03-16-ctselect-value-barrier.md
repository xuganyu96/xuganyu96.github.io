---
layout: post
title:  "Is my constant-time select actually constant-time?"
date:   2026-03-16 13:49:56 -0400
categories: cryptography
---

```c
#include <stdint.h>
#include <stdio.h>

void println_arr(const char *name, uint8_t *arr, size_t len) {
    printf("%s = [", name);
    for (int i = 0; i < len; i++) {
        printf("%02hhx", arr[i]);
        if (i + 1 < len) {
            printf(":");
        }
    }
    printf("]\n");
}

void ct_select(uint8_t *dst, uint8_t *iftrue, uint8_t *iffalse, size_t len,
               uint8_t selector) {
    // selector == 1 -> mask == 0xFF, selector == 0 -> mask == 0x00
    uint8_t mask = -selector;
    for (size_t i = 0; i < len; i++) {
        dst[i] = (iftrue[i] & mask) | (iffalse[i] & (~mask));
    }
}

int main() {
    uint8_t lhs[5] = {1, 1, 1, 1, 1};
    uint8_t rhs[5] = {2, 2, 2, 2, 2};
    uint8_t dst[5] = {0};
    ct_select(dst, lhs, rhs, sizeof(lhs), 1);

    println_arr("lhs", lhs, sizeof(lhs));
    println_arr("rhs", rhs, sizeof(rhs));
    println_arr("dst", dst, sizeof(dst));
}
```

Compiler:

```
Apple clang version 17.0.0 (clang-1700.6.4.2)
Target: arm64-apple-darwin25.3.0
Thread model: posix
InstalledDir: /Library/Developer/CommandLineTools/usr/bin
```

Compile commands:

```bash
clang -S -O0 ctselect.c -o ctselect-o0.S
clang -S -O1 ctselect.c -o ctselect-o1.S
clang -S -O3 ctselect.c -o ctselect-o3.S
```

Asseembly:
- [with -O0](/assets/artifacts/ctselect-o0.S)
- [with -O1](/assets/artifacts/ctselect-o1.S)
- [with -O3](/assets/artifacts/ctselect-o3.S)