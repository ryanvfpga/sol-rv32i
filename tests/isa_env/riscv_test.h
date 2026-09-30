
// Replaces riscv-tests/env/p/riscv_test.h. No CSRs, no ECALL/EBREAK/FENCE,
// no trap vector, no tohost/fromhost. Result is reported by writing to the
// top word of DMEM, which tb_top.v polls:
//
//     0x7FFC  <- 1 (PASS) or 2 (FAIL)
//     0x7FF8  <- failing TESTNUM (gp), written just before the FAIL code

#ifndef _ENV_BAREMETAL_H
#define _ENV_BAREMETAL_H

#define SIG_BASE     0x8000        /* first byte past DMEM; must be lui-loadable */
#define SIG_STATUS   -4            /* 0x7FFC */
#define SIG_TESTNUM  -8            /* 0x7FF8 */

#define TESTNUM gp                 /* same convention as upstream */

// Upstream rv32ui/*.S do: #undef RVTEST_RV64U / #define RVTEST_RV64U RVTEST_RV32U
#define RVTEST_RV32U  .macro init; .endm
#define RVTEST_RV64U  RVTEST_RV32U
#define RVTEST_CODE_BEGIN                                               \
        .section .text.init;                                            \
        .globl _start;                                                  \
_start:                                                                 \
        .irp reg,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,   \
            x16,x17,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,   \
            x30,x31;                                                    \
        li \reg, 0;                                                     \
        .endr;                                                          \
        init;


#define RVTEST_CODE_END


#define RVTEST_PASS                                                     \
        lui   t0, %hi(SIG_BASE);                                        \
        li    t1, 1;                                                    \
        sw    t1, SIG_STATUS(t0);                                       \
1:      j     1b;

#define RVTEST_FAIL                                                     \
        lui   t0, %hi(SIG_BASE);                                        \
        sw    TESTNUM, SIG_TESTNUM(t0);                                 \
        li    t1, 2;                                                    \
        sw    t1, SIG_STATUS(t0);                                       \
1:      j     1b;


#define EXTRA_DATA

#define RVTEST_DATA_BEGIN                                               \
        .align 4;                                                       \
        .global begin_signature;                                        \
begin_signature:

#define RVTEST_DATA_END                                                 \
        .align 4;                                                       \
        .global end_signature;                                          \
end_signature:

#endif