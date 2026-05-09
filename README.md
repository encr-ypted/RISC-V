# RV32I 5-Stage Pipelined CPU

## Overview
This is a 32-bit RISC-V processor (RV32I base integer instruction set) written from scratch in SystemVerilog. I built this as a personal project during my EEE degree to get hands-on experience with computer architecture, pipeline hazards, and modern RTL verification before pursuing FPGA roles in the low-latency/HFT space. 

The design implements a classic 5-stage pipeline and is targeted for synthesis on an Intel Cyclone IV E FPGA (Terasic DE0-Nano).

## Architecture Details
The CPU uses a standard 5-stage datapath (Instruction Fetch, Decode, Execute, Memory, Write-Back). To handle the complexities of pipelining without relying on software-inserted NOPs, the hardware dynamically manages dependencies:

*   **Data Hazards:** A dedicated Forwarding Unit bypasses the Register File to resolve EX-to-EX and MEM-to-EX data dependencies.
*   **Load-Use Hazards:** The CPU detects when an instruction requires data from an incomplete memory read. It asserts a stall signal that freezes the PC and IF/ID registers while injecting a bubble into the EX stage.
*   **Control Hazards:** Taken branches and jumps (JAL/JALR) calculate their target addresses in the EX stage. A taken branch triggers a flush of the IF/ID and ID/EX pipeline registers, resulting in a 2-cycle branch penalty.
*   **Struct-Based Routing:** SystemVerilog `packed struct` datatypes are used for the pipeline registers to cleanly bundle and route control/data signals between stages without cluttering the top-level wire mapping.

## Verification
The design is verified using `cocotb`.
*   **Unit Tests:** Each core module (ALU, Branch Unit, Decoder, etc.) has its own directed testbench to verify combinatorial logic and edge cases (e.g., ensuring `x0` is hardwired to zero).
*   **System Tests:** The top-level CPU is tested by loading compiled RISC-V assembly into the Instruction Memory. The testbench monitors the pipeline stages cycle-by-cycle to verify hazard resolution and checks final register states against expected values.

## Repository Structure

```text
├── quartus/                    # Quartus Prime project files and board constraints (.sdc, .qsf)
├── rtl/                        # Synthesizable SystemVerilog source
│   ├── core/                   # Datapath and control logic
│   │   ├── alu.sv
│   │   ├── branch_unit.sv
│   │   ├── control_unit.sv
│   │   ├── forwarding_unit.sv
│   │   ├── pc.sv
│   │   └── register_file.sv
│   ├── memory/                 # Inferred M9K BRAM modules
│   │   ├── data_memory.sv
│   │   └── instruction_memory.sv
│   ├── utils/                  
│   │   ├── cpu_pkg.sv          # Typedefs and packed structs for pipeline registers
│   │   └── pipeline_register.sv
│   └── cpu_top.sv              # Top-level datapath integration
├── tests/                      # Cocotb/Pytest verification environment
│   ├── core/                   
│   │   ├── test_alu.py
│   │   ├── test_branch_unit.py
│   │   ├── test_control_unit.py
│   │   ├── test_pc.py
│   │   └── test_register_file.py
│   ├── memory/                 
│   │   ├── test_data_memory.py
│   │   └── test_instruction_memory.py
│   ├── runner.py               # Pytest simulation execution script
│   └── test_cpu_top.py         # System-level pipeline and hazard testbench
├── .gitignore
├── program.asm                 # Assembly test programs
├── program.hex                 # Compiled machine code for Instruction Memory
├── README.md                   
└── requirements.txt            # Python dependencies