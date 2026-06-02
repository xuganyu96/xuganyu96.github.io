#include <stdint.h>
#include <stdio.h>

static inline uint64_t rdtsc(void) {
    uint32_t hi, lo;
    __asm__ volatile("rdtsc" : "=d"(hi), "=a"(lo));
    return ((uint64_t)hi << 32) | lo;
}

static inline uint64_t rdtscp(uint32_t *proc) {
    uint32_t hi, lo, _proc;
    __asm__ volatile("rdtscp" : "=d"(hi), "=a"(lo), "=c"(_proc));
    *proc = _proc;
    return ((uint64_t)hi << 32) | lo;
}

static inline void mfence(void) { __asm__ volatile("mfence" : : : "memory"); }

static inline void lfence(void) { __asm__ volatile("lfence" : : : "memory"); }

static inline void clflush(volatile void *p) {
    __asm__ volatile("clflush (%0)" : : "r"(p) : "memory");
}

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

static void pco_scan() {
    // TODO: implement this
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
