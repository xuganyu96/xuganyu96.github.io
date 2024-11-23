---
layout: post
title:  "Working with Kyber/ML-KEM"
date: 2024-11-22 11:55:43 -0400
categories: cryptography
---

I have had a few projects that require me to work with the source code of Kyber/ML-KEM. After a few attempts at setting up a development environment with which I can work within and/or on top of Kyber/ML-KEM, I have come to the following setup process for programming in C.

For doing a C project involving Kyber, I use the reference implementation found on [GitHub](https://github.com/pq-crystals/kyber). The best way to get it is as a git submodule, which can be set up using the following commands:

```bash
# this will clone the repo to the "kyber" subdirectory
git submodule add https://github.com/pq-crystals/kyber
# afterwards when cloning the parent project, git will retain a reference but no actual source code, so we need the following commands to clone the submodule again:
git submodule init
git submodule update
```

We need a way to include the source and header files. For source code within the parent project, it is easy to include the header files using relative paths. For example, the `main.c` file at the project root include the `indcpa.h` header from the reference implementation using:

```c
#include "kyber/ref/indcpa.h"
```

As for including Kyber's source files at compilation, I defined some macros in the Makefile:

```makefile
KYBERDIR = kyber/ref
KYBERSOURCES = $(KYBERDIR)/kem.c $(KYBERDIR)/indcpa.c $(KYBERDIR)/polyvec.c $(KYBERDIR)/poly.c $(KYBERDIR)/ntt.c $(KYBERDIR)/cbd.c $(KYBERDIR)/reduce.c $(KYBERDIR)/verify.c $(KYBERDIR)/randombytes.c
KYBERSOURCESKECCAK = $(KYBERSOURCES) $(KYBERDIR)/fips202.c $(KYBERDIR)/symmetric-shake.c
KYBERHEADERS = $(KYBERDIR)/params.h $(KYBERDIR)/kem.h $(KYBERDIR)/indcpa.h $(KYBERDIR)/polyvec.h $(KYBERDIR)/poly.h $(KYBERDIR)/ntt.h $(KYBERDIR)/cbd.h $(KYBERDIR)/reduce.c $(KYBERDIR)/verify.h $(KYBERDIR)/symmetric.h
KYBERHEADERSKECCAK = $(KYBERHEADERS) $(KYBERDIR)/fips202.h
CFLAGS += -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wpointer-arith -O3 -fomit-frame-pointer -Wno-incompatible-pointer-types
NISTFLAGS += -Wno-unused-result -O3 -fomit-frame-pointer

SOURCES = $(KYBERSOURCESKECCAK)
HEADERS = $(KYBERHEADERSKECCAK)

main: $(SOURCES) $(HEADERS) main.c
	$(CC) $(CFLAGS) $(LDFLAGS) $(SOURCES) main.c -o $@

# ... rest of the Makefile ...
```

Since I use Neovim with `clangd` as my language server, I need to configure `clangd` to know about Kyber, as well:

```yaml
CompileFlags:
  Add: [
    "-Wall", 
    "-Wextra", 
    "-Wpedantic", 
    "-Wmissing-prototypes", 
    "-Wredundant-decls", 
    "-Wshadow", 
    "-Wpointer-arith", 
    "-O3", 
    "-fomit-frame-pointer",
  ]
```