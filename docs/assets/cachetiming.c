#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define EPOCHS 1
#define ROUNDS 5
#define ROUND_FMT "%" PRIu32 ",%" PRIu32 ",%d,%lu,%lu\n"

typedef struct {
    size_t pklen;
    size_t sklen;
    size_t ctlen;
    size_t sslen;
    int (*crypto_kem_keypair)(uint8_t *pk, uint8_t *sk);
    int (*crypto_kem_enc)(uint8_t *ct, uint8_t *ss, const uint8_t *pk);
    int (*crypto_kem_dec)(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);
} kemsuite_t;

/* Dummy KEM */
#define VOIDKEM_PKLEN 64
#define VOIDKEM_SKLEN 64
#define VOIDKEM_CTLEN 64
#define VOIDKEM_SSLEN 32
#define VOIDKEM_SK_REJLOC 0
#define VOIDKEM_SK_REJLEN 32
#define VOIDKEM_EXPLOC VOIDKEM_SK_REJLEN
#define VOIDKEM_REFLOC VOIDKEM_SK_REJLEN

int voidkem_keypair(uint8_t *pk, uint8_t *sk) {
    memset(pk, 0, VOIDKEM_PKLEN);
    memset(sk, 0, VOIDKEM_SKLEN);
    return 0;
}

int voidkem_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk) {
    memset(ct, 0, VOIDKEM_CTLEN);
    memset(ss, 0, VOIDKEM_SSLEN);
    return 0;
}

int voidkem_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk) {
    uint8_t err = 0;
    for (int i = 0; i < VOIDKEM_CTLEN; i++) {
        err |= ct[i];
    }
    if (err) { /* only read rejection symbol on error */
        memcpy(ss, sk + VOIDKEM_SK_REJLOC, VOIDKEM_SK_REJLEN);
    }
    for (int i = VOIDKEM_SK_REJLEN; i < VOIDKEM_SKLEN; i++) {
        *(volatile char *)(sk + i);
    }
    return 0;
}

const static kemsuite_t voidkem = {
    .pklen = 64,
    .sklen = 64,
    .ctlen = 64,
    .sslen = 64,
    .crypto_kem_keypair = &voidkem_keypair,
    .crypto_kem_enc = &voidkem_enc,
    .crypto_kem_dec = &voidkem_dec,
};

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

/* FIX: randomly generate bits? */
static inline uint8_t corrupt_bit() { return 0x00; }

static int pco_scan(uint32_t epochs, uint32_t rounds, size_t exploc,
                    size_t refloc, const kemsuite_t *kem) {
    uint8_t *pk, *sk, *ct, *ss, *sscmp;
    uint64_t expdur, refdur;
    int rc = 0, corrupted;
    pk = malloc(kem->pklen);
    sk = malloc(kem->sklen);
    ct = malloc(kem->ctlen);
    ss = malloc(kem->sslen);
    sscmp = malloc(kem->sslen);
    if (!pk || !sk || !ct || !ss || !sscmp) {
        fprintf(stderr, "Failed to allocate pk, sk, ct, ss, or sscmp\n");
        rc = 1;
        goto cleanup;
    }

    for (uint32_t epoch = 0; epoch < epochs; epoch++) {
        kem->crypto_kem_keypair(pk, sk);
        for (uint32_t round = 0; round < rounds; round++) {
            kem->crypto_kem_enc(ct, ss, pk);
            ct[0] ^= corrupt_bit();

            clflush((void *)(sk + exploc));
            mfence();
            clflush((void *)(sk + refloc));
            mfence();
            corrupted = kem->crypto_kem_dec(sscmp, ct, sk);
            mfence();
            lfence();

            expdur = probe((void *)(sk + exploc));
            mfence();
            refdur = probe((void *)(sk + refloc));
            mfence();

            fprintf(stderr, ROUND_FMT, epoch, round, corrupted, expdur, refdur);
        }
    }

cleanup:
    if (pk)
        free(pk);
    if (sk)
        free(sk);
    if (ct)
        free(ct);
    if (ss)
        free(ss);
    if (sscmp)
        free(sscmp);
    return rc;
}

int calibrate(void) {
    fprintf(stderr, "Calibration:\n");
    uint8_t val = 0;
    uint64_t start, stop, dur;
    *(volatile char *)&val;

    for (int i = 0; i < 10; i++) {
        dur = probe(&val);
        fprintf(stderr, "hit  = %4lu, ", dur);

        clflush((void *)&val);
        mfence();
        dur = probe(&val);
        fprintf(stderr, "miss = %4lu\n", dur);
    }

    return 0;
}

int main(void) {
    calibrate();
    pco_scan(EPOCHS, ROUNDS, VOIDKEM_EXPLOC, VOIDKEM_REFLOC, &voidkem);

    return 0;
}
