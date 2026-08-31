# RISC-V RV32I Multi-Cycle Processor

A 32-bit **RISC-V RV32I multi-cycle processor** implemented in Verilog HDL. The design uses an FSM-based controller to divide instruction execution into multiple clock cycles while reusing the datapath resources across instruction classes.

The repository contains the complete RTL datapath, multi-cycle controller, instruction and data memories, immediate generator, register file, simulation testbench, architecture reference, and a verification waveform for the **sum of natural numbers** program.

---

## Features

- 32-bit RV32I datapath
- FSM-based multi-cycle control
- Separate instruction and data memories
- 32 × 32-bit register file
- Immediate generation for I, S, B, U, and J formats
- ALU operations:
  - ADD, SUB
  - AND, OR, XOR
  - SLL, SRL, SRA
  - SLT, SLTU
- Conditional branches:
  - BEQ, BNE
  - BLT, BGE
  - BLTU, BGEU
- Jumps:
  - JAL
  - JALR
- U-type instructions:
  - LUI
  - AUIPC
- Load/store instructions:
  - LB, LH, LW
  - LBU, LHU
  - SB, SH, SW
- Extensive debug outputs for waveform-based verification

---

## Multi-Cycle Architecture

In a multi-cycle processor, an instruction is divided into a sequence of clocked states rather than completing in a single clock cycle.

```text
                    +---------+
                    |  FETCH  |
                    +----+----+
                         |
                         v
                    +---------+
                    | DECODE  |
                    +----+----+
                         |
          +--------------+--------------+----------------+
          |              |              |                |
          v              v              v                v
       R / I-Type     LOAD / STORE    BRANCH           JUMP
          |              |              |                |
          v              v              v                v
       EXECUTE        ADDRESS       TARGET + CMP      TARGET
          |              |              |                |
          v              v              v                v
      WRITEBACK     MEM R/W         FETCH           WRITEBACK
```

The same ALU is reused for PC increment, arithmetic/logical operations, effective-address calculation, branch/jump target generation, LUI, and AUIPC. Intermediate results are retained in temporary registers between states.

---

## Datapath

### Program Counter

During fetch:

```text
PC_next = PC + 4
```

For control-transfer instructions, the PC can instead be loaded from the calculated target address. JALR additionally clears bit 0 of the target.

### Instruction Register

The fetched 32-bit instruction is stored in `IR`, allowing the instruction to remain available during later states.

### A and B Registers

During decode:

```text
A <= Register[rs1]
B <= Register[rs2]
```

These temporary registers hold source operands for later execution and memory states.

### ALUOut Register

`ALUOut` stores an ALU result between cycles. It is used for arithmetic results, effective addresses, and branch/jump targets.

### Memory Data Register

`MDR` captures data returned by a load operation before it is written back to the destination register.

---

## FSM Control States

The controller defines dedicated states for the major instruction paths:

| State | Function |
|---|---|
| `S_FETCH` | Fetch instruction and perform `PC + 4` |
| `S_DECODE` | Read `rs1` and `rs2` into A/B |
| `S_EXEC_R` | Execute R-type instruction |
| `S_EXEC_I` | Execute I-type arithmetic instruction |
| `S_WB_ALU` | Write `ALUOut` to `rd` |
| `S_MEM_ADDR` | Calculate load/store effective address |
| `S_MEM_READ` | Read memory into MDR |
| `S_MEM_WRITE` | Store B register to memory |
| `S_WB_LOAD` | Write MDR to `rd` |
| `S_BRANCH_TARGET` | Calculate branch target |
| `S_BRANCH_COMPARE` | Evaluate branch condition |
| `S_JAL_CALC` | Calculate JAL target |
| `S_JAL_WRITE` | Update PC and write `PC + 4` |
| `S_JALR_CALC` | Calculate JALR target |
| `S_JALR_WRITE` | Update PC and write `PC + 4` |
| `S_LUI` | Generate LUI result |
| `S_AUIPC` | Generate AUIPC result |

---

## Instruction Support

### R-Type

```text
ADD   SUB
AND   OR    XOR
SLL   SRL   SRA
SLT   SLTU
```

The ALU control uses `funct3` and instruction bit 30 (`funct7[5]`) to distinguish operations such as ADD/SUB and SRL/SRA. fileciteturn8file0L2-L2

### I-Type Arithmetic

```text
ADDI
ANDI
ORI
XORI
SLLI
SRLI
SRAI
SLTI
SLTIU
```

### Loads and Stores

The data memory is byte-addressable with **1024 bytes (1 KiB)** of storage. The implementation supports signed/unsigned byte and halfword loads as well as word loads, together with byte, halfword, and word stores. fileciteturn14file0L2-L2

For a word load, the bytes are reconstructed in little-endian order:

```text
LW -> { memory[addr+3],
        memory[addr+2],
        memory[addr+1],
        memory[addr] }
```

### Branches

The ALU generates three comparison signals:

```text
Zero  -> equality
Less  -> signed less-than
LessU -> unsigned less-than
```

The controller uses them to implement BEQ, BNE, BLT, BGE, BLTU, and BGEU. fileciteturn7file0L2-L2

### JAL

```text
Target = PC_old + Immediate
rd     = PC + 4
PC     = Target
```

### JALR

```text
Target = A + Immediate
rd     = PC + 4
PC     = Target & ~1
```

### LUI / AUIPC

```text
LUI   -> rd = Immediate
AUIPC -> rd = PC_old + Immediate
```

---

## Immediate Generation

`imm_gen.v` generates immediates according to the RV32I instruction format:

| Format | Use |
|---|---|
| I-type | Immediate ALU operations, loads, JALR |
| S-type | Stores |
| B-type | Conditional branches |
| U-type | LUI, AUIPC |
| J-type | JAL |

For branch and jump formats, the immediate generator places the required low-order zero bit in the generated value. fileciteturn10file0L2-L2

---

## Repository Structure

```text
RISC_V_Multi_Cycle/
│
├── architecture/
│   └── RV32I.png
│
├── rtl/
│   ├── ALU.v
│   ├── ALU_control_unit.v
│   ├── PC.v
│   ├── data.mem
│   ├── data_memory.v
│   ├── imm_gen.v
│   ├── instruction_mem.v
│   ├── multicycle_controller.v
│   ├── processor.v
│   ├── program.mem
│   └── register_file.v
│
├── simulation/
│   └── tb_processor.v
│
├── waveform/
│   └── waveform_sum.png
│
└── README.md
```

The repository structure currently separates the architecture reference, RTL, simulation testbench, and waveform output. fileciteturn1file0L2-L2

---

## RTL Modules

| Module | Description |
|---|---|
| `processor.v` | Top-level multi-cycle processor datapath and debug interface |
| `multicycle_controller.v` | FSM-based control unit |
| `ALU.v` | 32-bit arithmetic, logical, shift, and comparison operations |
| `ALU_control_unit.v` | Converts `ALUOp`, `funct3`, and `funct7[5]` into ALU control |
| `PC.v` | Program counter register |
| `register_file.v` | Integer register file |
| `instruction_mem.v` | Instruction memory loaded from `program.mem` |
| `data_memory.v` | Byte-addressable data memory |
| `imm_gen.v` | RV32I immediate generator |
| `program.mem` | Machine-code program used for simulation |
| `data.mem` | Data-memory initialization file |

The top-level processor exposes debug signals for the FSM state, PC, instruction, register operands, ALU, memory, writeback, and controller outputs. fileciteturn6file0L2-L2

---

## Program Used for Verification

The current `program.mem` contains:

```text
00500513
00000593
00100613
00c585b3
00160613
fec55ce3
0000006f
```

This machine-code program is used to verify the processor with the **sum of natural numbers** example. fileciteturn11file0L2-L2

The program exercises immediate arithmetic, register-register addition, a conditional backward branch, repeated fetch/decode/execute cycles, and program termination through a self-loop.

---

## Simulation

The testbench is located at:

```text
simulation/tb_processor.v
```

It includes:

- 10 ns clock period (`#5` high/low transitions)
- Active-low reset
- Processor instantiation
- Connections for the processor's debug outputs
- Simulation termination after 1000 ns

These behaviors are implemented directly in `tb_processor.v`. fileciteturn12file0L2-L2

### Simulation Flow

1. Compile all Verilog files in `rtl/` and `simulation/tb_processor.v`.
2. Keep `program.mem` accessible from the simulator working directory.
3. Start the simulation.
4. Inspect the FSM state and datapath/debug signals in the waveform viewer.
5. Verify that each instruction follows the expected sequence of multi-cycle states.

The instruction memory loads `program.mem` using `$readmemh` and indexes it with `read_addr[31:2]`. Because RV32I instructions are 32 bits = 4 bytes, bits `[1:0]` are discarded to convert the byte address into a word index. fileciteturn13file0L2-L2

---

## Waveform Verification

A captured waveform for the sum-of-natural-numbers program is provided at:

```text
waveform/waveform_sum.png
```

The waveform can be used to trace instruction execution through states such as:

```text
FETCH
  ↓
DECODE
  ↓
EXECUTE
  ↓
WRITEBACK
```

and for the loop branch:

```text
FETCH
  ↓
DECODE
  ↓
BRANCH TARGET
  ↓
BRANCH COMPARE
  ↓
FETCH
```

The waveform file is included in the repository under `waveform/`. fileciteturn5file0L2-L2

---

## Debugging the Processor

One of the main goals of this implementation is making internal processor behavior visible during simulation.

Useful signals include:

| Category | Signals |
|---|---|
| FSM | `debug_state` |
| PC | `debug_PC`, `debug_PC_old`, `debug_PC_next` |
| Instruction | `debug_instruction`, `debug_IR` |
| Registers | `debug_read_data1`, `debug_read_data2`, `debug_A`, `debug_B` |
| Immediate | `debug_immediate` |
| ALU | `debug_ALU_A`, `debug_ALU_B`, `debug_ALUControl`, `debug_ALU_result`, `debug_ALUOut` |
| Comparisons | `debug_Zero`, `debug_Less`, `debug_LessU` |
| Memory | `debug_mem_read_data`, `debug_MDR` |
| Writeback | `debug_writeback_data` |
| Enables | `debug_IRWrite`, `debug_AWrite`, `debug_BWrite`, `debug_ALUOutWrite`, `debug_MDRWrite` |
| Control | `debug_PCWrite`, `debug_RegWrite`, `debug_MemRead`, `debug_MemWrite` |
| MUX selects | `debug_ALUSrcA`, `debug_ALUSrcB`, `debug_ALUOp`, `debug_PCSource`, `debug_WriteBackSel` |

This makes it possible to validate not only the final register values, but also **why** each value is produced during each clock cycle.

---

## Why Multi-Cycle?

The multi-cycle organization provides a useful middle ground between single-cycle and pipelined implementations.

### Compared with a single-cycle processor

- The clock period does not have to accommodate the entire instruction path.
- The ALU and other datapath resources can be reused.
- Different instruction classes can take different numbers of cycles.

### Compared with a pipelined processor

- There is no need to maintain several instructions simultaneously in pipeline stages.
- Hazard detection, forwarding, and pipeline flush logic are not required for this basic multi-cycle organization.
- The FSM directly describes the control flow of each instruction.

---

## Design Highlights

The key architectural idea is **resource reuse controlled by sequencing**:

```text
FETCH          -> PC + 4
R/I EXECUTE    -> Arithmetic / Logic
MEM ADDRESS    -> Base + Offset
BRANCH TARGET  -> PC_old + Immediate
JAL TARGET     -> PC_old + Immediate
JALR TARGET    -> A + Immediate
LUI            -> 0 + Immediate
AUIPC          -> PC_old + Immediate
```

The temporary registers `IR`, `A`, `B`, `ALUOut`, and `MDR` hold intermediate values so the processor can continue an instruction across multiple clock cycles. The controller determines when those registers are written and which datapath sources are selected. fileciteturn6file0L2-L2

---

## Tools

The design is written in Verilog HDL and can be simulated using tools such as:

- Icarus Verilog
- Verilator
- ModelSim / Questa
- Vivado Simulator
- Cadence Xcelium

The RTL can also be used as a starting point for synthesis and further ASIC implementation work.

---

## Learning Objectives

This project demonstrates:

- RV32I instruction decoding
- Multi-cycle datapath design
- FSM-based processor control
- ALU and ALU-control design
- Immediate generation
- Register-file operation
- Byte-addressable memory
- Load/store formatting
- Branch and jump target calculation
- Clock-by-clock RTL verification
- Waveform-based debugging

---

## Author

**Mukt Shah**

[GitHub Profile](https://github.com/MuktShah)

---

## License

This project is intended for educational and development purposes. Add a project-specific open-source license file if formal redistribution terms are required.
