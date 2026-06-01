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

<!-- TODO: talk about clflush -->

## Flush then reload

## Statistical test

## References

- [Intel® 64 and IA-32 Architectures Software Developer’s Manual](https://software.intel.com/en-us/download/intel-64-and-ia-32-architectures-sdm-combined-volumes-1-2a-2b-2c-2d-3a-3b-3c-3d-and-4)
