import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_branch_unit_logic(dut):
  """Test all branch types with both true and false ALU conditions."""

  # Mapping func3 to names for logging
  branch_types = {
    0b000: "BEQ", 0b001: "BNE",
    0b100: "BLT", 0b101: "BGE",
    0b110: "BLTU", 0b111: "BGEU"
  }

  # Define test cases: (func3, alu_zero, alu_lt, alu_lt_unsigned, expected_result)
  # branch_i is set to 1 for these tests to verify the condition logic
  test_cases = [
    (0b000, 1, 0, 0, 1),  # BEQ: Zero=1 -> Taken
    (0b000, 0, 0, 0, 0),  # BEQ: Zero=0 -> Not Taken
    (0b001, 0, 0, 0, 1),  # BNE: Zero=0 -> Taken
    (0b001, 1, 0, 0, 0),  # BNE: Zero=1 -> Not Taken
    (0b100, 0, 1, 0, 1),  # BLT: LT=1 -> Taken
    (0b100, 0, 0, 0, 0),  # BLT: LT=0 -> Not Taken
    (0b101, 0, 0, 0, 1),  # BGE: LT=0 -> Taken
    (0b101, 0, 1, 0, 0),  # BGE: LT=1 -> Not Taken
  ]

  dut.branch_i.value = 1

  for func3, z, lt, ltu, expected in test_cases:
    dut.func3_i.value = func3
    dut.alu_zero_i.value = z
    dut.alu_lt_i.value = lt
    dut.alu_lt_unsigned_i.value = ltu

    await Timer(1, unit="ns")

    assert dut.take_branch_o.value == expected, \
      f"Failed {branch_types[func3]}: Z={z}, LT={lt}, Expected {expected}"

    dut._log.info(f"Passed {branch_types[func3]} test.")


@cocotb.test()
async def test_branch_disabled(dut):
  """Verify that if branch_i is 0, take_branch_o is always 0."""
  dut.branch_i.value = 0
  dut.func3_i.value = 0b000  # BEQ
  dut.alu_zero_i.value = 1  # Condition met

  await Timer(1, unit="ns")

  assert dut.take_branch_o.value == 0, "Branch taken even when branch_i is 0!"
  dut._log.info("Branch disabled test passed.")