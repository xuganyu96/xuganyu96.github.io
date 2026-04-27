---
layout: post
title:  "Integrating HQC into liboqs"
date:   2026-04-20 16:47:45 -0400
categories: cryptography
---

After the deprecation of the PQClean project, liboqs needs to source its HQC implementation else. This documents the journey of bringing HQC's reference implementation (hosted on GitLab) into liboqs. 

Some clarification on the vocabulary used here:
- A parameter set is a <!-- TODO: define a parameter set -->
- An implementation is a <!-- TODO: define what an implementation is -->

# Pulling from official repository
liboqs utilizes a Python script for automatically cloning the source files from a specified git repository. The same script also handles generating the CMake list file and some C code that glues the upstream code into liboqs' API. As of April 2026, the GitLab repository does not contain the necessary metadata files (such as [this one](https://github.com/pq-code-package/mlkem-native/blob/5d6774a56c90b5a0c02573a56d95d35c3c106ec5/integration/liboqs/ML-KEM-512_META.yml) for ML-KEM-512), which makes it difficult to work directly with the original repository. Instead, I created a GitHub repository under my own account and push-pulled the commits from the official repository, effectively making a fork/mirror of the official repository.

```bash
# TODO: git commands
git remote add <gitlab-url> <pqc-hqc.org>
```

Each parameter set (i.e. HQC-1, HQC-3, or HQC-5) requires its own metadata datasheet, which can be copied from other integrations, though the individual data fields need to be filled out appropriately. Afterwards, add appropriate entries to the `upstream` section and the `kems` section in liboqs' internal [datasheet](https://github.com/open-quantum-safe/liboqs/blob/3cb781fd4737c900ad755ee0bb9e1949d0f68955/scripts/copy_from_upstream/copy_from_upstream.yml). At this point, running the integration script should bring in the source code, generate the liboqs API source implementation, and generate the CMake list files.

# Apply namespacing
The official repository does not namespace the individual implementations, so we cannot compile all three parameter sets into a single static library. Instead, the official repository's [build configuration](https://gitlab.com/pqc-hqc/hqc/-/blob/next-release/src/CMakeLists.txt?ref_type=heads#L32) will build one static library per implementation:

```cmake
# 4) build one static library per variant
foreach(var IN LISTS VARIANTS)
    string(REPLACE "-" "_" safe ${var})
    # ... stuff ...
    add_library(${safe}_${HQC_ARCH} STATIC
        # ... source files ...
    )
    target_include_directories(${safe}_${HQC_ARCH} PUBLIC
        # ... includes ...
    )
    target_link_libraries(${safe}_${HQC_ARCH} PUBLIC
        # ... link fips 202 ...
    )
endforeach()
```

After the build, the static libraries are located under `./build/src/libhqc_<1|3|5>_ref.a`.

Without namespacing, each of `libhqc_<1|3|5>_<ref|x86_64>.a` contains symbols named `crypto_kem_keypair`, `crypto_kem_enc`, and `crypto_kem_dec` (the common crypto KEM API). Instead, we want to have three sets of distinctly named symbols `HQC<1|3|5>_crypto_kem_<keypair|enc|dec>`. To accomplish this namespacing, I borrowed from [mlkem-native's approach](https://github.com/pq-code-package/mlkem-native/blob/5d6774a56c90b5a0c02573a56d95d35c3c106ec5/mlkem/src/common.h#L47):

```c
/**
 * @file namespace.h
 * @brief C preprocessing macro for namespacing
 */

#ifndef HQC_NAMESPACE_H
#define HQC_NAMESPACE_H

#ifndef PQCHQC_NAMESPACE_PREFIX
#warning "PQCHQC_NAMESPACE_PREFIX is not defined, default to no namespace"
#define PQCHQC_NAMESPACE_PREFIX
#endif

#define PQCHQC_CONCAT_(lhs, rhs) lhs##rhs
#define PQCHQC_CONCAT(lhs, rhs) PQCHQC_CONCAT_(lhs, rhs)

#define PQCHQC_NAMESPACE(name) PQCHQC_CONCAT(PQCHQC_NAMESPACE_PREFIX, name)

#endif /* !HQC_NAMESPACE_H */
```

Per GPT-5 mini, the extra layer of indirection (`PQCHQC_NAMESPACE` calling `PQCHQC_CONCAT`, which then calls `PQCHQC_CONCAT_`) is necessary because macros are not expanded when pasted directly into `##`.

The namespacing prefix is defined by the C pre-processing macro `PQCHQC_NAMESPACE_PREFIX`, which I will specify in the `compile_opts` field in the liboqs integration data sheets, such as shown below:

```yaml
implementations:
- name: ref
  compile_opts: "-DHQC_ARCH_REF=1 -DPQCHQC_NAMESPACE_PREFIX=PQCHQC_HQC1_C_ -DUSE_OQS_RANDOMBYTES"
  signature_keypair: PQCHQC_HQC1_C_crypto_kem_keypair
  signature_enc: PQCHQC_HQC1_C_crypto_kem_enc
  signature_dec: PQCHQC_HQC1_C_crypto_kem_dec
```

Unfortunately this is not the end of the namespacing, because many internal subroutines in each of the static libraries have identical names but different behaviors. For example, let's look at `code_encode` under `src/common/code.c`:

```c
void code_encode(uint64_t *em, const uint64_t *m) {
    uint64_t tmp[VEC_N1_SIZE_64] = {0};
    reed_solomon_encode(tmp, m);
    reed_muller_encode(em, tmp);
    memset_zero(tmp, sizeof tmp);
}
```

The size of `tmp` depends on the macro `VEC_N1_SIZE_64`, which evaluates to 46 in HQC-1 (`src/ref/hqc-1/parameters.h`), 56 in HQC-3, and 90 in HQC-5. 

## A small detour on duplicate symbols
What happens when we have duplicate symbols? Here is a small example: `foo.c` and `bar.c` both implement a function `int foo(void)`, though `foo.c`'s implementation returns 0 and `bar.c`'s impl returns 1.

```shell
# outputs foo.o and bar.o
gcc -c foo.c bar.c
# combine the two object files into a single static library
ar rcs libfoo.a foo.o bar.o
```

Disassemble `libfoo.a`  with `objdump -d libfoo.a`, which reveals the existence of duplicate symbols:

```asm
In archive libfoo.a:

foo.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <foo>:
   0:	55                   	push   %rbp
   1:	48 89 e5             	mov    %rsp,%rbp
   4:	b8 00 00 00 00       	mov    $0x0,%eax
   9:	5d                   	pop    %rbp
   a:	c3                   	ret

bar.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <foo>:
   0:	55                   	push   %rbp
   1:	48 89 e5             	mov    %rsp,%rbp
   4:	b8 01 00 00 00       	mov    $0x1,%eax
   9:	5d                   	pop    %rbp
   a:	c3                   	ret
```

Now if we compile a binary `main.c` with `gcc main.c libfoo.a -o main`, running `main` will print `foo = 0`:

```c
#include <stdio.h>
#include "libfoo.h"

int main(void) {
    printf("foo = %d\n", foo());
    return 0;
}
```

Why is that? When we created `libfoo.a`, `foo.o` is placed before `bar.o`, so in `libfoo.a`, `foo.c`'s `foo` is placed before `bar.c`'s implementation. Then when the linker tries to find the `foo` symbol while linking `main.c` against `libfoo.a`, the linker uses the first one.

This means that if we swap the two source files and compile with `cc -c bar.c foo.c`, then the final binary will print `bar.c`'s implementation:

```bash
# Recall foo.c's impl returns 0, bar.c's impl returns 1
gcc -c bar.c foo.c
ar rcs libfoo.a foo.o bar.o
gcc -o main main.c libfoo.a
# Should print 1
./main
```

On the other hand, compiling all source files together will produce a "duplicate symbol" error:

```bash
gcc -o main main.c foo.c bar.c
```

## Namespacing internal symbols
Circling back to the task of namespacing internal routines of HQC: every symbol that is used in more than one source file should be namespaced, and everything else should be declared `static`.

# Replacing fips202 and randombytes

# NIST KAT

# Fixing `1UL` width inconsistency on Windows

# Switching from fork to patching

# Strange SHA3 failure

# Deliverables
