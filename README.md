# sol-rv32i

A 32-bit, 5-stage pipelined RISC-V processor based on the **RV32I ISA**. The main goal of this project is to understand and explore the principles of CPU microarchitecture.

## Microarchitecture

**sol-rv32i** features a standard 5-stage pipeline **(IF, ID, EX, MEM, WB)** and utilizes a Harvard memory architecture with 16KB Instruction and Data memory based in BRAM allowing for 1 cycle read/write latency.

**(Note: Because read latency is 1 cycle, this project does not implement an L1 Instruction/Data cache).**

#### Branch Prediction & Control Hazards
It also features a **2-bit dynamic branch predictor** and a **BTB (Branch Table Buffer)** to increase branch prediction accuracy compared to static branch prediction, 
and to also increase CPI by reducing pipeline flushes caused by branch mispredictions.
Branch prediction occurs in **IF** stage, and in case of misprediction both **IF** and **ID** stages have to be flushed invoking a 2-cycle penalty.


#### Data Hazards

RAW (Read-After-Write) Hazards are dynamically resolved, by detecting register dependencies in **EX** stage, and data is forwarded from **EX/MEM** or **MEM/WB** registers, in cases where both are present, **EX/MEM** is forwarded due to it being the more recent instruction. Load-Use Hazards are detected in the **ID** stage when an instruction depends on a preceding load. Inserts a 1-cycle pipeline stall before forwarding data from the **MEM/WB** register. **WB/ID** Register Conflicts are resolved at the register file level using by writing on negative edge, and reading on positive edge to prevent conflicts.




## Instruction Set Architecture

Implemented 37 of the 40 base RV32I instructions, System exceptions (`ECALL`, `EBREAK`) and memory synchronization (`FENCE`) are omitted due to not being part of the microarchitectural scope.


| Format | Instruction Type | Implemented Instructions |
| :--- | :--- | :--- |
| **R-Type** | Register-Register Operations | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| **I-Type** | Immediate Operations & Loads | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`, `JALR`, `LB`, `LH`, `LW`, `LBU`, `LHU` |
| **S-Type** | Store Operations | `SB`, `SH`, `SW` |
| **B-Type** | Conditional Branches | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| **U-Type** | Upper Immediate Operations | `LUI`, `AUIPC` |
| **J-Type** | Unconditional Jumps | `JAL` |


## Testing

To run the test suites, clone the repository first:

```bash
git clone https://github.com/ryanvfpga/sol-rv32i.git
cd sol-rv32i
```

### Prerequisites

* **Icarus Verilog (`iverilog`)**: Required for all Verilog simulations, as well as running the C test programs.

* **RISC-V Toolchain (`riscv32-unknown-elf-gcc`)**: Required only if compiling and running C test programs in `sw/programs/`.

### Flags

```bash
# To simulate verilog testbenches, as well as C Programs
python run_tests.py

# To only simulate verilog testbenches
python run_tests.py -v

# To only compile and simulate C Programs (NOTE: This still requires iverilog under the hood to simulate after compilation)
python run_tests.py -c

```
To add your own verilog testbenches or C Programs you can add them under `tb/` or `sw/programs/` respectively, ensure that both of them follow the general format of pre-existing testbenches/programs because `run_tests.py` relies on a generalized **PASS/FAIL** output from the simulator.
