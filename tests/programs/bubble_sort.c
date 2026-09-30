/*
 * bench_suite.c - self-checking benchmark suite for a bare-metal RV32I core.
 *
 * - Pure RV32I: no mul/div/rem anywhere, no libgcc, no libc.
 * - Static data is ~2.3 KB, so it fits a 4 KB DMEM (and of course 32 KB).
 * - Every kernel is checked against a known checksum.
 * - Each kernel is bracketed by writes to MARK_ADDR so the testbench can
 *   snapshot mcycle/minstret/branch counters per kernel:
 *        start of kernel k : MARK = (k << 1) | 1
 *        end   of kernel k : MARK =  k << 1
 *
 * Kernels (what they stress):
 *   1 bubble sort, random data  - unpredictable data-dependent branches
 *   2 sieve of Eratosthenes     - nested loops, byte stores (sb/lbu)
 *   3 recursive fibonacci       - jal/jalr, call/return, stack traffic
 *   4 linked-list traversal     - back-to-back load-use hazards
 *   5 bitwise CRC32             - shifts, tight 8-iteration inner loop
 *
 * Addresses assume the original 4 KB DMEM (stack top 0x0FF0). If you move to
 * 32 KB with __stack_top = 0x7FF0, change the three addresses below to
 * 0x7FF8 / 0x7FFC / 0x7FF4.
 */

typedef unsigned int u32;

#ifndef NATIVE
#define MARK_ADDR   ((volatile u32 *)0x00000FF8)
#define RESULT_ADDR ((volatile u32 *)0x00000FFC)   /* 1 = pass, 2 = fail */
#define FAILID_ADDR ((volatile u32 *)0x00000FF4)   /* id of first failing kernel */
#define MARK(v)     (*MARK_ADDR = (v))
#else
#include <stdio.h>
#define MARK(v)     ((void)(v))
#endif


#define N_SORT   128
#define N_SIEVE  1024
#define N_LIST   64
#define N_CRC    256

static u32 rng_state = 0x12345678u;

static inline u32 xorshift32(void)
{
    u32 x = rng_state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    rng_state = x;
    return x;
}

static inline u32 rotl5(u32 h) { return (h << 5) | (h >> 27); }

/* ---------------- 1: bubble sort on pseudo-random data ---------------- */
static int sort_arr[N_SORT];

static u32 k_bubble(void)
{
    for (int i = 0; i < N_SORT; i++)
        sort_arr[i] = (int)(xorshift32() & 0xFF);

    for (int i = 0; i < N_SORT - 1; i++) {
        for (int j = 0; j < N_SORT - 1 - i; j++) {
            if (sort_arr[j] > sort_arr[j + 1]) {
                int t = sort_arr[j];
                sort_arr[j] = sort_arr[j + 1];
                sort_arr[j + 1] = t;
            }
        }
    }

    u32 h = 0;
    for (int i = 0; i < N_SORT; i++)
        h = rotl5(h) ^ (u32)sort_arr[i];
    return h;
}

/* ---------------- 2: sieve of Eratosthenes ---------------- */
static unsigned char sieve[N_SIEVE];

static u32 k_sieve(void)
{
    for (int i = 0; i < N_SIEVE; i++) sieve[i] = 1;
    sieve[0] = 0;
    sieve[1] = 0;

    for (int i = 2; i < 32; i++) {              /* 32 = sqrt(N_SIEVE), avoids a multiply */
        if (sieve[i]) {
            for (int j = i + i; j < N_SIEVE; j += i)
                sieve[j] = 0;
        }
    }

    u32 count = 0;
    for (int i = 0; i < N_SIEVE; i++) count += sieve[i];
    return count;
}

/* ---------------- 3: recursive fibonacci ---------------- */
static u32 __attribute__((noinline)) fib(u32 n)
{
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

static u32 k_fib(void) { return fib(17); }

/* ---------------- 4: linked-list pointer chasing ---------------- */
struct node { struct node *next; u32 val; };
static struct node list[N_LIST];

static u32 k_list(void)
{
    for (int i = 0; i < N_LIST; i++) {
        list[i].next = &list[(i + 37) & (N_LIST - 1)];   /* 37 is odd -> one cycle of 64 */
        list[i].val  = (u32)i ^ 0x5Au;
    }

    u32 sum = 0;
    struct node *p = &list[0];
    for (int pass = 0; pass < 32; pass++) {
        for (int i = 0; i < N_LIST; i++) {
            sum += p->val;       /* load val, then load next: load-use chains */
            p = p->next;
        }
    }
    return sum;
}

/* ---------------- 5: bitwise CRC32 ---------------- */
static unsigned char crc_buf[N_CRC];

static u32 k_crc(void)
{
    for (int i = 0; i < N_CRC; i++)
        crc_buf[i] = (unsigned char)(xorshift32() >> 24);

    u32 crc = 0xFFFFFFFFu;
    for (int i = 0; i < N_CRC; i++) {
        crc ^= crc_buf[i];
        for (int b = 0; b < 8; b++) {
            if (crc & 1u) crc = (crc >> 1) ^ 0xEDB88320u;
            else          crc >>= 1;
        }
    }
    return ~crc;
}

/* ---------------- driver ---------------- */
typedef u32 (*kernel_fn)(void);

static const kernel_fn kernels[5] = { k_bubble, k_sieve, k_fib, k_list, k_crc };

/* Reference values: computed natively and cross-checked in Python (CRC via zlib) */
static const u32 expected[5] = {
    0x9df59a24u, 0x000000acu, 0x0000063du, 0x0002fc00u, 0x5d1e3c7eu
};

int main(void)
{
    u32 failed = 0;

    for (u32 k = 0; k < 5; k++) {
        MARK(((k + 1) << 1) | 1);
        u32 r = kernels[k]();
        MARK((k + 1) << 1);

#ifdef NATIVE
        printf("kernel %u checksum = 0x%08x\n", k + 1, r);
#endif
        if (r != expected[k] && !failed)
            failed = k + 1;
    }

#ifndef NATIVE
    if (failed) *FAILID_ADDR = failed;
    *RESULT_ADDR = failed ? 2 : 1;
    while (1);
#else
    printf("failed=%u\n", failed);
#endif
    return 0;
}