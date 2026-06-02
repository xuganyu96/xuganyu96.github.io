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
    __asm__ volatile("clflush (%0)" : : "r"(p));
}
```

## Flush then reload

With a CPU clock, memory/load fences, and cache eviction, we can build a simple
probing program to demonstrate the timing difference between cache hit and cache
miss:

```c
int main(void) {
    uint8_t val = 0;
    uint64_t start, stop, dur;
    *(volatile char *)&val;

    for (int i = 0; i < 10; i++) {
        mfence();
        start = rdtsc();
        lfence();
        *(volatile char *)&val;
        mfence();
        stop = rdtsc();
        lfence();

        printf("hit  = %lu, ", stop - start);

        clflush((void *)&val);
        mfence();
        start = rdtsc();
        lfence();
        *(volatile char *)&val;
        mfence();
        stop = rdtsc();
        lfence();

        printf("miss = %lu\n", stop - start);
    }

    return 0;
}
```

On my ThinkPad X1, the program produced the following output:

```bash
cc -O3 main.c -o main.out && main.out
hit  = 104, miss = 374
hit  = 104, miss = 380
hit  = 106, miss = 376
hit  = 108, miss = 386
hit  = 106, miss = 380
hit  = 106, miss = 382
hit  = 106, miss = 376
hit  = 108, miss = 376
hit  = 106, miss = 378
hit  = 110, miss = 380
```

## Statistical test

## References

- [x86_64 instruction reference](https://www.felixcloutier.com/x86/)
- [Intel® 64 and IA-32 Architectures Software Developer’s Manual](https://software.intel.com/en-us/download/intel-64-and-ia-32-architectures-sdm-combined-volumes-1-2a-2b-2c-2d-3a-3b-3c-3d-and-4)
