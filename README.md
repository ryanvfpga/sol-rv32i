# sol-rv32i

A 32-bit, 5-stage pipelined RISC-V processor based on the **RV32I ISA**. The main goal of this project is to understand and explore the principles of CPU microarchitecture.

## Microarchitecture

sol-rv32i utilizes a classic 5-stage pipeline **(IF, ID, EX, MEM, WB)** with a **Harvard Architecture**, featuring **4KB of Instruction Memory and 4KB of Data Memory** located in BRAM with single-cycle read/write capabilities.
**(Note: Because read latency is 1 cycle, this project does not implement an L1 Instruction/Data cache).**


Although, pipelining increases the throughput of the processor, it also introduces certain data and control hazards.

#### Data Hazards

* RAW (Read-After-Write) Hazards are dynamically resolved, by detecting register dependencies in **EX** stage, and data is forwarded from **EX/MEM** or **MEM/WB** registers, in cases where both are present, **EX/MEM** is forwarded due to it being the more recent instruction.

* Load-Use Hazards are detected in the **ID** stage when an instruction depends on a preceding load. Inserts a 1-cycle pipeline stall before forwarding data from the **MEM/WB** register.

* WB/ID Register Conflicts are resolved at the register file level using by writing on negative edge, and reading on positive edge to prevent conflicts.

#### Control Hazards

* Branches are resolved in **EX** stage, and we always predict that the branch is not taken and hence fetch the 2 subsequent instructions.

* In case of a misprediction, the **IF/ID** and **ID/EX** registers need to be flushed, and thus we will incur a 2-cycle penalty.




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


