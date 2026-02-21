# RTL-Implementation-of-an-In-Order-5-Stage-RV32I-Pipeline

This project implements a **minimal in-order 5-stage pipelined RISC-V processor (RV32I)** using Verilog/SystemVerilog.
The design follows the **classic 5-stage pipeline model** and focuses on clear stage separation, pipeline registers,
and instruction flow across the pipeline.

This implementation is intended for **educational and architectural understanding** of pipelined CPU design.

---

## 🧠 Pipeline Architecture

The processor is organized into the standard **5 RISC pipeline stages**:

| Stage | Name | Description |
|------:|------|-------------|
| 1 | IF | Instruction Fetch |
| 2 | ID | Instruction Decode & Register Read |
| 3 | EX | Execute (ALU operations) |
| 4 | MEM | Memory Access (pass-through stage) |
| 5 | WB | Write Back |

Each stage is implemented as a **separate RTL module**, with dedicated pipeline registers:
- IF/ID
- ID/EX
- EX/MEM
- MEM/WB

---

## 1️⃣ Instruction Fetch (IF)

- Fetches 32-bit instructions from an internal instruction memory.
- Maintains a program counter (PC) that increments by 4 every cycle.
- Instruction memory is word-aligned.
- Outputs the fetched instruction and current PC to the IF/ID pipeline register.

---

## 2️⃣ Instruction Decode (ID)

- Decodes RV32I instruction fields:
  - Source registers: `rs1`, `rs2`
  - Destination register: `rd`
  - Immediate value (currently supports **I-type format**)
- Reads source operands from the register file.
- Handles register write-back from the WB stage.
- Register `x0` is hardwired to zero as per RISC-V specification.

---

## 3️⃣ Execute (EX)

- Performs ALU operations.
- Current implementation supports:
  - `add`
  - `addi`
- The ALU operation result is forwarded to the EX/MEM pipeline register.
- The EX stage is easily extensible to support additional RV32I operations.

---

## 4️⃣ Memory Access (MEM)

- Acts as a pass-through stage in the current implementation.
- Included to preserve correct 5-stage pipeline structure.
- Placeholder for future data memory integration to support `lw` and `sw`.

---

## 5️⃣ Write Back (WB)

- Writes computation results back to the register file.
- Ensures register `x0` remains unchanged.
- Completes instruction execution.

---

## 🧾 Register File

- 32 general-purpose registers (`x0`–`x31`)
- Dual read ports and single write port
- Asynchronous reads
- Synchronous writes
- `x0` is hardwired to zero

---

## 💾 Instruction Memory

The instruction memory is preloaded with RV32I instructions for demonstration and testing purposes.

### Example Instructions

| Address | Hex Value  | Assembly Instruction |
|--------:|------------|----------------------|
| 0x00 | 0x00000013 | `addi x0, x0, 0` (NOP) |
| 0x04 | 0x00100093 | `addi x1, x0, 1` |
| 0x08 | 0x00200113 | `addi x2, x0, 2` |
| 0x0C | 0x00308193 | `addi x3, x1, 3` |
| 0x10 | 0x00410213 | `addi x4, x2, 4` |

Additional NOP instructions are included to flush the pipeline.

---

## 🧩 Supported Instructions

### I-Type
- `addi`

### R-Type
- `add`

---

## 🔧 RTL Modules

- `pipeline_5stage.v`  
  Top-level module integrating all pipeline stages

- `if_stage.v`  
  Program counter and instruction fetch logic

- `if_id_reg.v`  
  IF/ID pipeline register

- `id_stage.v`  
  Instruction decode and register file

- `id_ex_reg.v`  
  ID/EX pipeline register

- `ex_stage.v`  
  ALU execution stage

- `ex_mem_reg.v`  
  EX/MEM pipeline register

- `mem_stage.v`  
  Memory stage (pass-through)

- `mem_wb_reg.v`  
  MEM/WB pipeline register

- `wb_stage.v`  
  Write-back logic

---

## 📘 Instruction Flow Example

Instruction: `addi x3, x1, 3`

| Stage | Operation |
|------:|----------|
| IF | Fetch instruction |
| ID | Decode and read `x1` |
| EX | ALU computes `x1 + 3` |
| MEM | Pass-through |
| WB | Write result to `x3` |

---

## 🚫 Limitations

- No data forwarding
- No branch or jump support
- No load/store instructions
- No hazard detection beyond basic stalling
- Minimal RV32I subset implementation

---

## 🎯 Purpose

This project demonstrates:
- RTL-based pipeline implementation
- Instruction flow across pipeline stages
- Modular CPU design using Verilog/SystemVerilog

It serves as a foundation for extending toward a complete RV32I processor.

---

## 👨‍💻 Author

**Kiran Kumar Siripurapu**  
B.Tech, Electronics and Communication Engineering  
RGUKT Srikakulam  

---

## 📂 License

This project is intended for educational and personal use.
