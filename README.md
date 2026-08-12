# 32-bit ARM-based ALU Architecture Design & ASIC Implementation

Personal hardware design project implementing a high-performance 32-bit Arithmetic Logic Unit (ALU) based on the ARM instruction set architecture (ISA). 

## Project Overview & Objectives
The goal of this project is to gain hands-on experience in high-speed digital circuit design and complete an ASIC implementation flow—from RTL modeling to physical design.

Key Learning Outcomes & Engineering Focus:
- Deep understanding of microarchitecture design for Arithmetic Logic Units (ALUs).
- Hands-on application of the ARM 32-bit instruction set architecture (ISA) opcodes and operation modes.
- Production-level RTL coding in Verilog/SystemVerilog.
- Practice with industry-standard Electronic Design Automation (EDA) synthesis and P&R tools, specifically **Synopsys Design Compiler** (Logic Synthesis) and **Cadence Innovus** (Place and Route / Physical Design).

## What is an ALU?
An **Arithmetic Logic Unit (ALU)** is a fundamental combinational building block of a Central Processing Unit (CPU). It receives control signals and data operands to execute mathematical operations (such as addition and subtraction) as well as bitwise logical operations (AND, OR, XOR, etc.).

## Architecture & Operation Principles

The top-level ALU architecture processes two 32-bit input operands (`a` and `b`) in parallel through four internal functional sub-units:

1. **Kogge-Stone Adder (KSA):** A high-speed parallel-prefix carry-lookahead adder chosen for low-latency addition and subtraction operations.
2. **Bitwise AND Unit**
3. **Bitwise OR Unit**
4. **Bitwise XOR Unit (EOR)**

### Execution Flow:
1. Both 32-bit inputs (`a` and `b`) are broadcast to all functional units simultaneously.
2. Each unit computes its respective operation in parallel.
3. Based on the incoming 4-bit **Opcode** control signal, an output Multiplexer (MUX) routes the single valid operation result to the final 32-bit ALU output port (`result`).

## Opcode & Control Unit Mapping

The control unit decodes the **4-bit Opcode** input signal to select the appropriate execution unit and multiplexer path. 

Below is the control mapping implemented for the 32-bit ARM data-processing instruction format:

| Opcode (`[3:0]`) | Mnemonic | Operation Name | Description & RTL Action |
| :---: | :---: | :---: | :--- |
| `0100` | **ADD** | Addition | `Result = A + B` |
| `0010` | **SUB** | Subtraction | `Result = A - B` *(Calculated via 2's complement using KSA)* |
| `0000` | **AND** | Bitwise AND | `Result = A & B` |
| `1100` | **ORR** | Bitwise OR | `Result = A \| B` |
| `0001` | **EOR** | Bitwise Exclusive-OR | `Result = A ^ B` |


## Toolchain & Implementation Flow
- **RTL Simulation:** Icarus Verilog / Verilator (via Visual Studio Code)
- **Logic Synthesis:** Synopsys Design Compiler
- **Place & Route (P&R):** Cadence Innovus

## Future Plan
- Design efficient ALU using CSA
- Design Multiplier and Divider
