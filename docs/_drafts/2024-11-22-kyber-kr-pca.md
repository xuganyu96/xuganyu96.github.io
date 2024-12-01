---
layout: post
title:  "Key-Recovery Plaintext-Checking Attack against Kyber/ML-KEM"
date: 2024-11-22 11:55:43 -0400
categories: cryptography
---
Because of the search-decision equivalence of the Learning with Error (LWE) problem (see [Pei16 Section 4.2.2](https://eprint.iacr.org/2015/939.pdf) for details), Kyber/ML-KEM and many other lattice cryptosystems are known to be vulnerable to plaintext-checking attacks (PCA). Even with Fujisaki-Okamoto transformation, timing variability in implementation can be converted into a plaintext-checking oracle and subsequently a devastating side-channel attacks that can recover the entire secret key using only a few thousand traces ([Ueno21](https://eprint.iacr.org/2021/849)). In this blog post, we will review the mathematics of the plaintext-checking attack, then go through a few recently discovered side-channel attacks against Kyber/ML-KEM.

# Mathematical description
Kyber/ML-KEM constructs an IND-CCA secure key encapsulation mechanism (KEM) in two steps. First it defines an IND-CPA secure public key encryption (PKE) scheme, then the Fujisaki-Okamoto transformation is applied to convert the IND-CPA PKE into an IND-CCA KEM. In this section, we will focus on attacking the IND-CPA PKE (which we will call CPAPKE for the rest of the post).

A CPAPKE ciphertext contains two components: a polynomial vector $$\mathbf{u} \in R^k$$ and a polynomial $$v \in R$$, where $$R = \mathbb{Z}_q[x]/\langle x^n + 1\rangle$$. The secret key is also a polynomial vector $$\mathbf{s} \in R^k$$, although the coefficients are all very small (for ML-KEM-512 they range from -3 to 3; for ML-KEM-768/1024 they range from -2 to 2). At decryption, we first compute $$\hat{m} \leftarrow v - \langle \mathbf{s}, \mathbf{u} \rangle$$, then round the coefficients of $$\hat{m}$$ based on whether they are closer to $$q/2$$ (rounds to 1) or $$0$$ (rounds to 0). After rounding $$\hat{m}$$ has 256 coefficients that are either 0 or 1, which encodes a 256-bit secret.

This decryption routine has no resistance to active attacks. An active adversary can craft malicious ciphertext, then observe the behavior of the decryption routine and learn something about the secret key. Specifically for ML-KEM, a malicious ciphertext can be crafted as follows:

1. Pick some integer $$1 \leq i^\ast \leq k$$ and some integer $$1 \leq j^\ast \leq n$$
1. Pick some integer $$u^\prime \in \mathbb{Z}_q$$, set the polynomial vector $$\mathbf{u} \in R^k$$ to be all zeros except for the $$i^\ast$$-th polynomial, which is set to the constant $$u^\prime$$
1. Pick some integer $$v^\prime \in \mathbb{Z}_q$$, set the $$j^\ast$$-th coefficient of $$v$$ to be $$v^\prime$$ and all other coefficients to zero

Given this malformed ciphertext, we can observe the decryption computation:

TODO: write this part

```
compressed_u: 0b01000000, u: 208
compressed_v: 0b0000, v:     0, pattern: [0, 0, 0, 0, 0, 0, 0]
compressed_v: 0b0001, v:   208, pattern: [0, 0, 0, 0, 0, 0, 0]
compressed_v: 0b0010, v:   416, pattern: [1, 0, 0, 0, 0, 0, 0]
compressed_v: 0b0011, v:   624, pattern: [1, 1, 0, 0, 0, 0, 0]
compressed_v: 0b0100, v:   832, pattern: [1, 1, 1, 0, 0, 0, 0]
compressed_v: 0b0101, v:  1040, pattern: [1, 1, 1, 1, 0, 0, 0]
compressed_v: 0b0110, v:  1248, pattern: [1, 1, 1, 1, 1, 0, 0]
compressed_v: 0b0111, v:  1456, pattern: [1, 1, 1, 1, 1, 1, 0]
compressed_v: 0b1000, v:  1664, pattern: [1, 1, 1, 1, 1, 1, 1]
compressed_v: 0b1001, v: -1456, pattern: [0, 1, 1, 1, 1, 1, 1]
compressed_v: 0b1010, v: -1248, pattern: [0, 0, 1, 1, 1, 1, 1]
compressed_v: 0b1011, v: -1040, pattern: [0, 0, 0, 1, 1, 1, 1]
compressed_v: 0b1100, v:  -832, pattern: [0, 0, 0, 0, 1, 1, 1]
compressed_v: 0b1101, v:  -624, pattern: [0, 0, 0, 0, 0, 1, 1]
compressed_v: 0b1110, v:  -416, pattern: [0, 0, 0, 0, 0, 0, 1]
compressed_v: 0b1111, v:  -208, pattern: [0, 0, 0, 0, 0, 0, 0]
```

# Development setup
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

## Benchmarking AES performance on AWS
This is unrelated but on AWS' `c7a.medium` instance, the following commands produced the following results:

```
[ec2-user@ip-172-31-7-7 .pyenv]$ openssl speed -elapsed -evp aes-128-cbc
You have chosen to measure elapsed time instead of user CPU time.
Doing AES-128-CBC for 3s on 16 size blocks: 216148322 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 64 size blocks: 63381694 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 256 size blocks: 16600886 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 1024 size blocks: 4178464 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 8192 size blocks: 526050 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 16384 size blocks: 261952 AES-128-CBC's in 3.00s
version: 3.0.8
built on: Wed Sep 18 00:00:00 2024 UTC
options: bn(64,64)
compiler: gcc -fPIC -pthread -m64 -Wa,--noexecstack -O2 -ftree-vectorize -flto=auto -ffat-lto-objects -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -fstack-protector-strong -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1  -m64 -march=x86-64-v2 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -O2 -ftree-vectorize -flto=auto -ffat-lto-objects -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -fstack-protector-strong -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -march=x86-64-v2 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -Wa,--noexecstack -Wa,--generate-missing-build-notes=yes -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -DOPENSSL_USE_NODELETE -DL_ENDIAN -DOPENSSL_PIC -DOPENSSL_BUILDING_OPENSSL -DZLIB -DNDEBUG -DPURIFY -DDEVRANDOM="\"/dev/urandom\"" -DREDHAT_FIPS_VERSION="\"3.0.8-398f843fdf69322f\"" -DSYSTEM_CIPHERS_FILE="/etc/crypto-policies/back-ends/openssl.config"
CPUINFO: OPENSSL_ia32cap=0xfefa320b078bffff:0x405f5af1bf05a9
The 'numbers' are in 1000s of bytes per second processed.
type             16 bytes     64 bytes    256 bytes   1024 bytes   8192 bytes  16384 bytes
AES-128-CBC    1152791.05k  1352142.81k  1416608.94k  1426249.05k  1436467.20k  1430607.19k
[ec2-user@ip-172-31-7-7 .pyenv]$ OPENSSL_ia32cap="~0x200000200000000" openssl speed -elapsed -evp aes-128-cbc
You have chosen to measure elapsed time instead of user CPU time.
Doing AES-128-CBC for 3s on 16 size blocks: 53821954 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 64 size blocks: 13866331 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 256 size blocks: 3520158 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 1024 size blocks: 889818 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 8192 size blocks: 110594 AES-128-CBC's in 3.00s
Doing AES-128-CBC for 3s on 16384 size blocks: 55074 AES-128-CBC's in 3.00s
version: 3.0.8
built on: Wed Sep 18 00:00:00 2024 UTC
options: bn(64,64)
compiler: gcc -fPIC -pthread -m64 -Wa,--noexecstack -O2 -ftree-vectorize -flto=auto -ffat-lto-objects -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -fstack-protector-strong -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1  -m64 -march=x86-64-v2 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -O2 -ftree-vectorize -flto=auto -ffat-lto-objects -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -fstack-protector-strong -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -march=x86-64-v2 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -Wa,--noexecstack -Wa,--generate-missing-build-notes=yes -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -DOPENSSL_USE_NODELETE -DL_ENDIAN -DOPENSSL_PIC -DOPENSSL_BUILDING_OPENSSL -DZLIB -DNDEBUG -DPURIFY -DDEVRANDOM="\"/dev/urandom\"" -DREDHAT_FIPS_VERSION="\"3.0.8-398f843fdf69322f\"" -DSYSTEM_CIPHERS_FILE="/etc/crypto-policies/back-ends/openssl.config"
CPUINFO: OPENSSL_ia32cap=0xfcfa3209078bffff:0x0 env:~0x200000200000000
The 'numbers' are in 1000s of bytes per second processed.
type             16 bytes     64 bytes    256 bytes   1024 bytes   8192 bytes  16384 bytes
AES-128-CBC     287050.42k   295815.06k   300386.82k   303724.54k   301995.35k   300777.47k
```

|input block size|KB/sec with AES-NI|KB/sec processed without AES-NI|
|:--|:--|:--|
|16|1152791.05|287050.42 (-75.1%)|
|64|1352142.81|295815.06 (-78.1%)|
|256|1416608.94|300386.82 (-78.8%)|
|1024|1426249.05|303724.54 (-78.7%)|
|8192|1436467.20|301995.35 (-79.0%)|
|16384|1430607.19|300777.47 (-79.0%)|
