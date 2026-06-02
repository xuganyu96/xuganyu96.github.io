---
layout: post
title: "Flush-then-reload side channel"
date: "2026-06-01 14:43:04 -0400"
---

<!-- https://github.com/open-quantum-safe/liboqs/tree/208e941bed4ff363c72ac257de53ff30b34cce4c -->

1. Building blocks: timestamp counters, fences, volatile read, force eviction
2. Constructing the test
3. Statistical test

## Basic building blocks

This naive flush-then-reload side channel requires the ability to read accurate
CPU time that can differentiate between the duration of a cold miss and a cache
hit. The difference is usually on the scale of nanoseconds, and some kind of
CPU cycle counter would be the most preferrable. A second requirement is control
over cache: some way to eviction a value from cache, and some way to load a
value from memory into cache. Last but not least, we need some memory and load
fences to ensure that the compiler and the CPU will respect proper order of
execution.

### High precision clock

On x86_64, `rdtsc` and `rdtscp` are the most commonly used instruction for
reading CPU cycles. Both instructions **R**ea**D** from **T**ime**S**tamp
**C**ounter. `rdtscp` additional reads the processor ID. Both output a 64-bit
value that is split across two 32-bit registers: `EDX` for the high-order bits,
`EAX` for the lower-order bits.

For a simple example, we can use inline assembly to read the output of `rdtsc`
into two 32-bit variables:

```c
static inline uint64_t rdtsc(void) {
    uint32_t high, low;
    __asm__ volatile("rdtsc" : "=a"(low), "=d"(high));
    return ((uint64_t) high << 32) | low;
}

static inline uint64_t rdtscp(uint32_t *proc) {
    uint32_t high, low, _proc;
    __asm__ volatile("rdtscp" : "=a"(low), "=d"(high), "=c"(_proc));
    *proc = _proc;
    return ((uint64_t) high << 32) | low;
}
```

### Memory and load fence

Modern CPUs implement speculative execution to improve performance, but it also
means that assembly instructions might be executed out of the order in which
they are written. This can impact the accuracy of the measurements. x86_64
provides these two instructions for ensuring certain order of execution:

- The load fence (`lfence`) performs a serializing operation on all
load-from-memory instructions issued prior to the fence. The fence is not
executed until all prior load operations are completed. All instructions after
the fence do not execute until the fence is completed.
- The memory fence (`mfence`) performs a serializing operation on all
load-from-memory instructions **and store-to-memory instructions** issued prior
to the fence. All load and store operations before the fence are guaranteed to
be globally visible before all load and store operations after the fence.

They can be similarly invoked with inline assembly. Note that we need to add
`memory` to the clobber field. The `memory` directive instructs the compiler
to not reorder load and store instructions at the assembly level, while the
fences instruct the CPU to not reorder the execution of the load/store
instructions.

```c
static inline mfence(void) {
    __asm__ volatile("mfence" : : : "memory");
}

static inline lfence(void) {
    __asm__ volatile("lfence" : : : "memory");
}
```

### Cache eviction

The core of a cache timing side channel is the attacker's ability to distinguish
between cache hit and cache miss. When a program asks for some data from the
memory, it is possible that the requested data already resides in CPU cache,
which is significantly faster to read than memory. We don't know exactly how
the CPU decides to cache data, but we do know that recently accessed data is
more likely to be cached than less recently accessed data.

On x86_64, the `clflush` instruction invalidates the cache line that contains
the linear address specified with the memory operand, so we can reliably evict
some specified data from cache and reproduce a cache miss. On the other hand,
we can use a volatile read to bring some data into the cache. Note though that
the `volatile` keyword only instructs the compiler to not optimize the read
instruction away and does not correlate with hardware behavior.

```c
static inline void clflush(volatile void *p) {
    __asm__ volatile("clflush (%0)" : : "r"(p) : "memory");
}
```

## Flush then reload

With a CPU clock, memory/load fences, and cache eviction, we can build a simple
probing program to demonstrate the timing difference between cache hit and cache
miss:

```c
static inline uint64_t probe(void *p) {
    volatile char sink;
    uint64_t start, stop, dur;

    mfence();
    lfence();
    start = rdtsc();
    lfence();

    sink = *(volatile char *)p;
    (void)sink;

    lfence();
    stop = rdtsc();
    lfence();

    dur = stop - start;
    return dur;
}

int main(void) {
    uint8_t val = 0;
    uint64_t start, stop, dur;
    *(volatile char *)&val;

    for (int i = 0; i < 10; i++) {
        dur = probe(&val);
        printf("hit  = %4lu, ", dur);

        clflush((void *)&val);
        mfence();
        dur = probe(&val);
        printf("miss = %4lu\n", dur);
    }

    return 0;
}
```

On my ThinkPad X1, the program produced the following output, which (loosely)
confirms that a cache miss indeed takes longer to execute than a cache hit.

```bash
cc -O3 main.c -o main.out && main.out
hit  =   40, miss =  280
hit  =   38, miss =  252
hit  =   38, miss =  250
hit  =   40, miss =  250
hit  =   40, miss =  254
hit  =   38, miss =  406
hit  =   40, miss =  246
hit  =   40, miss =  254
hit  =   42, miss =  252
hit  =   40, miss =  250
```

## Application to side channel attacks on FO-transformed KEMs

Modern key encapsulation mechanisms (KEM) commonly deploy the Fujisaki-Okamoto
transformation to convert a passively secure encryption scheme into an actively
secure encryption scheme. The core technique used in the transformation is
called *re-encryption*: in the decryption subroutine, the ciphertext is first
decrypted, then the decryption is encrypted under the same encryption key,
whose output is compared with the input ciphertext. If the re-encryption is
identical to the input ciphertext, then the input ciphertext is considered
valid, so the true secret is returned. If the re-encryption is not identical
to the input ciphertext, then the input ciphertext is considered to have been
tempered with, and a fake pseudorandom secret will be returned. The security
model requires that the attacker cannot tell the fake secret from the true
secret.

The fake secret is pseudorandomly derived from a secret value (called implicit
rejection) embedded in the secret key. In a faulty implementation, it is
possible that when the ciphertext is valid, the program will not execute the
branch computing the fake secret, so that region of the secret key is not read,
whereas if the ciphertext is not valid, then this region of the secret key is
read. If an attacker can force cache eviction on the secret key, run
decryption, and probe the location of implicit rejection with sufficient
precision, then it may be able to distinguish valid ciphertext from invalid
ciphertext. This amounts to a plaintext-checking oracle (PCO) and violates
the security model.

We can write a simple program that automates this procedure by taking advantage
of the common API shared across all post-quantum KEMs submitted to the NIST
Post-Quantum Cryptography standardization project:

```c
int crypto_kem_keypair(uint8_t *pk, uint8_t *sk);
int crypto_kem_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk);
int crypto_kem_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);
```

<!-- write the test -->

## Statistical test

In the example above, the timing difference between cache hit and cache miss is
highly distinguishable. In real world examples, however, the difference may not
be as visible. For more rigorous tests, we will require statistical methods.

<!-- TODO: modify the program so user can supply its own routine and locs -->

## References

- [x86_64 instruction reference](https://www.felixcloutier.com/x86/)
- [Intel® 64 and IA-32 Architectures Software Developer’s Manual](https://software.intel.com/en-us/download/intel-64-and-ia-32-architectures-sdm-combined-volumes-1-2a-2b-2c-2d-3a-3b-3c-3d-and-4)
