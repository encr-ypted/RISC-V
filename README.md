# 🚀 RV32I-Core: A Single-Cycle RISC-V Processor on FPGA

## Project Overview

This project implements a fully functional 32-bit RISC-V (RV32I Base Integer Instruction Set) CPU from scratch using SystemVerilog. Designed and verified as a personal initiative during my 3rd/4th year EEE studies, this processor demonstrates a complete understanding of CPU architecture, datapath design, control logic, and modern hardware verification methodologies.

The CPU is a **single-cycle Von Neumann architecture**, meaning it fetches instructions and data from a single memory space within a single clock cycle. It is designed for deployment on an Intel/Altera Cyclone IV E FPGA (specifically the Terasic DE0-Nano development board).

## Key Features & Architectural Components

*   **RISC-V RV32I ISA Support:** Implements the full base integer instruction set.
*   **Modular Datapath:** Cleanly separated into distinct, testable modules:
    *   **Program Counter (PC):** Handles sequential, branch, and jump target updates.
    *   **Instruction Memory (IMEM):** Stores executable machine code (`.hex` file).
    *   **Data Memory (DMEM):** Supports word-aligned memory reads/writes with byte-enable capability (currently hard-wired for word access).
    *   **Register File:** 32x32-bit general-purpose registers, correctly handling `x0` (zero register) behavior and dual-read/single-write ports.
    *   **Arithmetic Logic Unit (ALU):** Performs all RV32I arithmetic (ADD, SUB), logical (AND, OR, XOR), and shift operations (SLL, SRL, SRA), including signed (SLT) and unsigned (SLTU) comparisons.
*   **Robust Control Unit:**
    *   Decodes all RV32I instruction formats (R, I, S, B, U, J-Type).
    *   Generates all necessary datapath control signals (e.g., `RegWrite`, `MemWrite`, `ALUSrc`, `ResultSrc`, `PC_Sel`).
    *   Includes a dedicated **Immediate Generator** for all instruction types (I, S, B, U, J), including complex bit-scrambling and sign-extension.
*   **Branch/Jump Logic:** Dedicated combinatorial logic to evaluate branch conditions (BEQ, BNE, BLT, BGE, BLTU, BGEU) and determine next PC based on ALU flags.
*   **Unified Next PC Logic:** A central MUX in `cpu_top` selects the next PC from `PC+4`, `PC-relative targets`, or `Register-relative targets` (for JALR).
*   **Write-Back MUX:** Selects data for register write-back from ALU result, Data Memory, or `PC+4` (for link instructions).

## Technologies Used

*   **Hardware Description Language (HDL):** SystemVerilog
*   **Verification Framework:** `cocotb` (Python-based) with `pytest`
*   **Simulation Tool:** Mentor Graphics QuestaSim (or Intel ModelSim)
*   **FPGA Toolchain:** Intel Quartus Prime Lite Edition
*   **Target Hardware:** Terasic DE0-Nano (Intel Cyclone IV E EP4CE22F17C6)
*   **Assembler:** RISC-V GNU Toolchain / Online RISC-V Assemblers (for `.hex` generation)

## Architecture Overview

The `cpu_top.sv` module integrates all sub-modules into a single-cycle datapath. The design follows a classic Von Neumann architecture, where the Program Counter drives an Instruction Memory, whose output is fed to the Control Unit. The Control Unit's outputs then orchestrate the Register File, ALU, and Data Memory. The final result is written back to the Register File, and the next PC is determined.

*(Optional: Add a simplified block diagram here if you have one!)*

## Key Achievements & Learning Outcomes

*   **End-to-End CPU Design:** Successfully designed, implemented, and integrated every major component of a modern CPU.
*   **Complex Control Logic Mastery:** Implemented multi-level instruction decoding, including complex immediate generation and control signal orchestration.
*   **Advanced Verification Practices:** Utilized `cocotb` for robust, cycle-accurate testing, including randomized stimulus generation, golden model comparison (implicitly in test functions), and understanding of synchronous testbench methodologies (e.g., `FallingEdge` for input changes, `ReadOnly` for output sampling).
*   **Hardware Debugging Proficiency:** Gained hands-on experience using industry-standard tools like QuestaSim for waveform analysis and Quartus Prime for synthesis and place-and-route.
*   **Understanding Hardware-Software Interface:** Bridged the gap between high-level assembly language and low-level hardware execution.
*   **Modular & Maintainable RTL:** Focused on creating clean, reusable, and well-organized SystemVerilog code, adhering to industry best practices.

## Getting Started (Simulation)

To run the `cocotb` simulations:

1.  **Clone the repository:** `git clone [your-repo-link]`
2.  **Navigate to the project root:** `cd [your-repo-name]`
3.  **Ensure prerequisites:** Python 3.x, `pip`, `cocotb`, `cocotb-test`, `pytest`, and a Verilog simulator (QuestaSim/ModelSim or Icarus Verilog).
4.  **Create `program.hex`:** Place your RISC-V machine code (e.g., the `ADDI/ADD/SUB` example) in `program.hex` in the root directory.
5.  **Run tests:** `make` (for Icarus) or `make SIM=questa` (for QuestaSim). Use `make SIM=questa GUI=1` to open the QuestaSim waveform viewer for detailed debugging.

### Example `program.hex` (Loads 3, 4, then calculates 3-4 = -1)

```text
00300093
00400113
402081b3
0000006f
