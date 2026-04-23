import cocotb
from cocotb.triggers import Timer

# --- Helper Constants (Opcodes) ---
OP_R_TYPE = 0b0110011
OP_I_ALU = 0b0010011
OP_I_LOAD = 0b0000011
OP_S_STORE = 0b0100011
OP_B_BR = 0b1100011
OP_J_JAL = 0b1101111
OP_I_JALR = 0b1100111
OP_U_LUI = 0b0110111


# --- Mini Assembler Helper Functions ---
# These pack the fields into a 32-bit RISC-V instruction
def pack_r_type(funct7, rs2, rs1, funct3, rd, opcode):
  return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | \
    ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def pack_i_type(imm, rs1, funct3, rd, opcode):
  return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | \
    ((rd & 0x1F) << 7) | (opcode & 0x7F)


# Converts Python's signed integers to 32-bit unsigned for comparison
def to_u32(val):
  return val & 0xFFFFFFFF


@cocotb.test()
async def test_r_type_add(dut):
  """Test R-Type Instruction: ADD x1, x2, x3"""
  # funct7=0, rs2=3, rs1=2, funct3=0, rd=1
  inst = pack_r_type(0, 3, 2, 0, 1, OP_R_TYPE)

  dut.instruction_i.value = inst
  await Timer(1, unit="ns")  # Wait for combinatorial logic

  assert dut.reg_write_o.value == 1
  assert dut.mem_write_o.value == 0
  assert dut.alu_b_src_o.value == 0
  assert dut.result_src_o.value == 0
  assert dut.pc_sel_o.value == 0
  assert dut.alu_op_sel_o.value == 0  # ADD

  dut._log.info("ADD (R-Type) decoded perfectly.")


@cocotb.test()
async def test_i_type_addi_negative(dut):
  """Test I-Type Instruction with Negative Immediate: ADDI x1, x2, -15"""
  imm_val = -15
  inst = pack_i_type(imm_val, 2, 0, 1, OP_I_ALU)

  dut.instruction_i.value = inst
  await Timer(1, unit="ns")

  assert dut.reg_write_o.value == 1
  assert dut.alu_b_src_o.value == 1  # Must use immediate
  assert dut.alu_op_sel_o.value == 0  # ADDI uses ADD

  # Check if sign extension worked!
  # Python represents -15 as a standard int. We convert to 32-bit hex for check.
  expected_imm = to_u32(imm_val)
  actual_imm = int(dut.immediate_o.value)
  assert actual_imm == expected_imm, f"Imm mismatch! Expected {hex(expected_imm)}, got {hex(actual_imm)}"

  dut._log.info("ADDI (I-Type) and negative sign-extension works.")


@cocotb.test()
async def test_load_word(dut):
  """Test I-Type Load: LW x5, 16(x10)"""
  inst = pack_i_type(16, 10, 0b010, 5, OP_I_LOAD)

  dut.instruction_i.value = inst
  await Timer(1, unit="ns")

  assert dut.reg_write_o.value == 1
  assert dut.result_src_o.value == 1  # MUST route memory to register!
  assert dut.mem_write_o.value == 0
  assert dut.alu_b_src_o.value == 1
  assert int(dut.immediate_o.value) == 16

  dut._log.info("LW (Load) decoded perfectly.")


@cocotb.test()
async def test_jalr(dut):
  """Test JALR Instruction: JALR x0, x1, 4"""
  inst = pack_i_type(4, 1, 0, 0, OP_I_JALR)

  dut.instruction_i.value = inst
  await Timer(1, unit="ns")

  assert dut.is_jalr_o.value == 1  # Critical check
  assert dut.pc_sel_o.value == 2  # Jump active
  assert dut.result_src_o.value == 2  # Save PC+4 to register
  assert dut.alu_b_src_o.value == 1  # ALU adds rs1 + imm

  dut._log.info("JALR decoded perfectly.")


@cocotb.test()
async def test_invalid_opcode(dut):
  """Test how the CPU handles a garbage/zero instruction"""
  dut.instruction_i.value = 0x00000000
  await Timer(1, unit="ns")

  # All state-changing signals should be 0 safely
  assert dut.reg_write_o.value == 0
  assert dut.mem_write_o.value == 0
  assert dut.pc_sel_o.value == 0

  dut._log.info("Safe defaults verified for garbage instruction.")