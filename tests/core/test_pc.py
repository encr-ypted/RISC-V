import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly


async def reset_dut(dut):
  """Resets the PC module."""
  dut.rst.value = 1
  # Drive a dummy value to next_pc_i during reset
  dut.next_pc_i.value = 0xAAAAAAAA
  await RisingEdge(dut.clk)
  dut.rst.value = 0
  await RisingEdge(dut.clk)


@cocotb.test()
async def test_pc_increment(dut):
  """Test that the PC registers the value provided at next_pc_i."""
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  await reset_dut(dut)

  # We drive the next_pc_i, the PC should capture it on the next edge
  expected_values = [4, 8, 12, 16]

  for val in expected_values:
    await FallingEdge(dut.clk)
    dut.next_pc_i.value = val
    await RisingEdge(dut.clk)
    await ReadOnly()

    assert dut.pc_o.value == val, f"Expected {val}, got {dut.pc_o.value}"
    dut._log.info(f"PC captured: {int(dut.pc_o.value)}")


@cocotb.test()
async def test_pc_reset(dut):
  """Test that the PC resets to 0 even if next_pc_i is driving garbage."""
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  # 1. Let it run for a bit
  dut.rst.value = 0
  dut.next_pc_i.value = 0xDEADBEEF
  await RisingEdge(dut.clk)
  await ReadOnly()
  assert dut.pc_o.value == 0xDEADBEEF


  # 2. Reset mid-execution
  dut._log.info("Applying reset...")
  await FallingEdge(dut.clk)

  dut.rst.value = 1
  # Even if next_pc_i is still driving garbage...
  dut.next_pc_i.value = 0x12345678

  await RisingEdge(dut.clk)
  await ReadOnly()

  # 3. Verify it snapped to 0
  assert dut.pc_o.value == 0, f"PC failed to reset, got {hex(int(dut.pc_o.value))}"
  dut._log.info("PC reset successfully to 0.")


@cocotb.test()
async def test_pc_warm_start(dut):
  """Test that it can start incrementing again after a reset."""
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  await reset_dut(dut)

  # Verify we are at 0
  assert dut.pc_o.value == 0

  # Start driving
  dut.next_pc_i.value = 4
  await RisingEdge(dut.clk)
  await ReadOnly()

  assert dut.pc_o.value == 4
  dut._log.info("PC resumed incrementing after reset.")