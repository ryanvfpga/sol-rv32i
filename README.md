# sol-rv32i

A 32-bit, 5-stage pipelined RISC-V processor based on the **RV32I ISA** and validated on official riscv-tests, designed and implemented to understand the core principles of CPU microarchitecture.

### Features

* 5 stage pipeline with IF, ID, EX, MEM, WB.
* Implemented 37 out of the 40 base RV32I instructions, excluding FENCE, ECALL and EBREAK.
* Harvard architecture with 32KB of Instruction and Data memory implemented with on-chip BRAM with single-cycle read/write latency.
*   Dynamic data hazard handling through forwarding from EX/MEM or MEM/WB stage, with 1-cycle stall on load-use hazards.
* Register write/read staggered on positive/negative clock edges to prevent structural hazards between ID and WB.
* 2 bit bimodal branch predictor with 256 entry tagged BTB (Branch Target Buffer) to reduce pipeline flushes caused by control hazards and increase IPC.
* Validated on `riscv-tests/rv32ui`: Passed 38/40 tests (**excluding fence_i and ma_data**), using a custom memory mapped PASS/FAIL environment (see [Testing](#testing)).

**(Note: Because memory is constrained to BRAM, this project does not implement an L1 Instruction/Data cache).**

## Architecture

[To Be Added]



## Performance

 4 different programs were compiled using  the `-O1` flag, and compared Cycles, CPI and Branch predictor accuracy between a 2-bit bimodal predictor with BTB and a static predictor (Always not-taken)

Bubble sort and merge sort only show modest improvement due to data dependent branches.

| Configuration | Cycles | CPI | Accuracy |
|---|---|---|---|
| bubblesort, always not-taken | 78153 | 1.478 | 71.06% |
| bubblesort, 2-bit + BTB | 66063 | 1.250 | 85.08% |
| insertionsort, always not-taken | 39343 | 1.481 | 50.03% |
| insertionsort, 2-bit + BTB | 31109 | 1.171 | 98.39% |
| matmul, always not-taken | 518171 | 1.357 | 48.92% |
| matmul, 2-bit + BTB | 400981 | 1.050 | 91.95% |
| mergesort, always not-taken | 45691 | 1.263 | 71.18% |
| mergesort, 2-bit + BTB | 41387 | 1.144 | 81.26% |




## Testing

To run the test suites, clone the repository first:

```bash
git clone https://github.com/ryanvfpga/sol-rv32i.git
cd sol-rv32i/
```

### Prerequisites

* **Icarus Verilog (iverilog)**: Required for running any type(s) of tests.

* **RISC-V Toolchain (riscv32-unknown-elf-gcc)**: Required only if compiling and running C test programs in `tests/programs/` or running `tests/riscv-tests`.

By default, running without flags simulates **everything** (Verilog testbenches, C, and riscv-tests).


```bash
python run_tests.py [flag]
```

**Optional Flags:**
* `-v` : Run verilog testbenches only.
* `-c` : Run C programs only 
* `-i` : Run riscv-tests only 



`riscv-tests/rv32ui` uses ECALL/tohost to report test results, since this core does not implement them, we use a custom header to write PASS/FAIL response to **0x7FFC**, and failing test number to **0x7FF8**, which the testbench then polls. The Stack pointer is initialised just below this region.

To add your own verilog testbenches or C Programs you can add them under `tb/` or `tests/programs/` respectively, ensure that both of them follow the general format of pre-existing testbenches/programs because `run_tests.py` relies on a generalized **PASS/FAIL** output from the simulator (for testbenches) or a **PASS/FAIL** code written into **0x7FFC** for C-Programs.

## Future Work

* Add support for M-extension, to support the full RV32IM ISA.

* Add CSR support to enable trap handling and interrupts.

* Port and benchmark CPU against CoreMark and report findings.

* Add L1 I/D cache to support external DDR memory on Zynq7020 FPGA.






