#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define EPOCHS 6
#define ROUNDS 6
#define CSV_HEADER "  epoch,  round,  corrupted,          target,         control\n"
#define ROUND_FMT "%7" PRIu32 ",%7" PRIu32 ",%11d,%16zu,%16zu\n"

const static uint64_t dlogprng_mod = 0xFFFFFFFB;
const static size_t dlogprng_chunk_bytes = 4;
const static uint64_t dlogprng_base = 65535;
static uint64_t dlogprng_state = 0;

static void dlogprng_init(void) {
    dlogprng_state = dlogprng_base;
}

static uint32_t dlogprng_getrandomu32(void) {
#if 0
    fprintf(stderr, "PRNG state = %04x\n", (uint32_t) dlogprng_state);
#endif
    uint32_t rand = (uint32_t) dlogprng_state & 0xFFFFFFFF;
    dlogprng_state = (dlogprng_state * dlogprng_base) % dlogprng_mod;
    return rand;
}

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
#define VOIDKEM_PKLEN 2048
#define VOIDKEM_SKLEN 2048
#define VOIDKEM_CTLEN 768
#define VOIDKEM_SSLEN 32
#define VOIDKEM_SK_REJLOC 0
#define VOIDKEM_SK_REJLEN 32
#define VOIDKEM_EXPLOC VOIDKEM_SK_REJLOC
#define VOIDKEM_REFLOC (VOIDKEM_SKLEN - 16)

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
#if 1
    if (err) { /* only read rejection symbol on error */
        memcpy(ss, sk + VOIDKEM_SK_REJLOC, VOIDKEM_SK_REJLEN);
    }
#endif
#if 0
    for (int i = VOIDKEM_REFLOC; i < VOIDKEM_SKLEN; i++) {
        /* another region is always read */
        *(volatile char *)(sk + i);
    }
#endif
    return 0;
}

const static kemsuite_t voidkem = {
    .pklen = VOIDKEM_PKLEN,
    .sklen = VOIDKEM_SKLEN,
    .ctlen = VOIDKEM_CTLEN,
    .sslen = VOIDKEM_SSLEN,
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
static inline uint8_t corrupt_bit() { 
    return ((uint8_t) dlogprng_getrandomu32()) & 1;
}

static int pco_scan(uint32_t epochs, uint32_t rounds, size_t exploc,
                    size_t refloc, const kemsuite_t *kem) {
    uint8_t *pk, *sk, *ct, *ss, *sscmp, corrupted;
    uint64_t expdur, refdur;
    int rc = 0;
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

    fprintf(stderr, CSV_HEADER);
    for (uint32_t epoch = 0; epoch < epochs; epoch++) {
        kem->crypto_kem_keypair(pk, sk);
        for (uint32_t round = 0; round < rounds; round++) {
            kem->crypto_kem_enc(ct, ss, pk);
            corrupted = corrupt_bit();
            ct[0] ^= corrupted;

            clflush((void *)(sk + exploc));
            mfence();
            clflush((void *)(sk + refloc));
            mfence();
            kem->crypto_kem_dec(sscmp, ct, sk);
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

    for (int i = 0; i < 5; i++) {
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
    dlogprng_init();
    calibrate();
    pco_scan(EPOCHS, ROUNDS, VOIDKEM_EXPLOC, VOIDKEM_REFLOC, &voidkem);

    return 0;
}
