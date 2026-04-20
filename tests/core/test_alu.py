import cocotb
from cocotb.triggers import Timer
import random


# Define the opcodes to match your Verilog module. This makes the test readable.
# This is a good practice instead of using "magic numbers" in the test.
class AluOps:
  ADD = 0b0000
  SUB = 0b0001
  AND = 0b0010
  OR = 0b0011
  XOR = 0b0100
  SLL = 0b0101
  SRL = 0b0110
  SRA = 0b0111
  SLT = 0b1000
  SLTU = 0b1001


def to_signed(val, bits):
  """Converts a two's complement unsigned integer to a signed integer."""
  if (val & (1 << (bits - 1))) != 0:  # if sign bit is set
    val = val - (1 << bits)  # compute negative value
  return val


def get_expected_result(op, a, b):
  """Python 'golden model' to calculate the expected ALU result."""
  mask = 0xFFFFFFFF  # Mask to ensure 32-bit behavior

  if op == AluOps.ADD:
    return (a + b) & mask
  if op == AluOps.SUB:
    return (a - b) & mask
  if op == AluOps.AND:
    return a & b
  if op == AluOps.OR:
    return a | b
  if op == AluOps.XOR:
    return a ^ b
  if op == AluOps.SLL:
    return (a << (b & 0x1F)) & mask
  if op == AluOps.SRL:
    return (a >> (b & 0x1F)) & mask
  if op == AluOps.SRA:
    # This is the tricky one. We must convert to signed for Python's arithmetic shift.
    signed_a = to_signed(a, 32)
    return (signed_a >> (b & 0x1F)) & mask
  if op == AluOps.SLT:
    signed_a = to_signed(a, 32)
    signed_b = to_signed(b, 32)
    return 1 if signed_a < signed_b else 0
  if op == AluOps.SLTU:
    return 1 if a < b else 0

  return 0  # Default


@cocotb.test()
async def test_alu_randomized(dut):
  """Run a randomized test on all ALU operations."""

  op_list = [
    AluOps.ADD, AluOps.SUB, AluOps.AND, AluOps.OR, AluOps.XOR,
    AluOps.SLL, AluOps.SRL, AluOps.SRA, AluOps.SLT, AluOps.SLTU
  ]

  for i in range(500):  # Run 500 random iterations
    # Generate random inputs
    a = random.randint(0, 0xFFFFFFFF)
    b = random.randint(0, 0xFFFFFFFF)
    op = random.choice(op_list)

    # Drive the DUT
    dut.a_i.value = a
    dut.b_i.value = b
    dut.opsel_i.value = op

    # Wait for the combinatorial logic to settle
    await Timer(1, unit="ns")

    # Get the actual result from the DUT
    actual_result = dut.result_o.value.integer
    actual_zero = dut.zero_o.value

    # Get the expected result from our Python model
    expected_result = get_expected_result(op, a, b)
    expected_zero = 1 if expected_result == 0 else 0

    # Create a detailed failure message
    fail_msg = (
      f"Random test {i} failed! Operation: {op}, "
      f"a=0x{a:08X}, b=0x{b:08X}\n"
      f"Expected: 0x{expected_result:08X}, Got: 0x{actual_result:08X}"
    )

    assert actual_result == expected_result, fail_msg
    assert actual_zero == expected_zero, f"Zero flag failed for operation {op}"

  dut._log.info("Randomized ALU test passed 500 iterations!")


@cocotb.test()
async def test_sra_negative_number(dut):
  """A directed test to specifically check the SRA bug."""
  a = 0xFFFFFFFC  # -4 in two's complement
  b = 1  # Shift right by 1

  dut.a_i.value = a
  dut.b_i.value = b
  dut.opsel_i.value = AluOps.SRA

  await Timer(1, unit="ns")

  actual = dut.result_o.value.integer
  expected = 0xFFFFFFFE  # -2 in two's complement

  assert actual == expected, (
    f"SRA test failed for negative number! "
    f"Expected 0x{expected:08X}, got 0x{actual:08X}"
  )
  dut._log.info("Directed SRA test for negative number passed.")