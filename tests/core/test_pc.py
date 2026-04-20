import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ReadOnly, ReadWrite
from cocotb.clock import Clock
import math

async def reset_dut(dut):
  dut.rst.value = 1
  await RisingEdge(dut.clk)
  dut.rst.value = 0

# @cocotb.test()
# async def test_pc_counter_increment(dut):
#   cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
#
#   dut.rst.value = 1
#   dut.jmp.value = 0
#
#   await RisingEdge(dut.clk)
#   dut.rst.value = 0
#   await ReadOnly()
#
#   dut._log.info(f"The initial pc value is {int(dut.pc_o.value)}")
#
#
#   for i in range(1, 5):
#     await RisingEdge(dut.clk)
#     await ReadOnly()
#
#     pc_value = dut.pc_o.value
#     dut._log.info(f"In the {i}th cycle the pc value is {int(pc_value)}")
#
#     assert pc_value == i * 4, "Failed at instruction {i}"
#
# @cocotb.test()
# async def test_pc_reset(dut):
#   cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
#
#   await reset_dut(dut)
#
#   for i in range(5):
#     await RisingEdge(dut.clk)
#
#   await ReadOnly()
#
#   pc_value = dut.pc_o.value
#   dut._log.info(f"In the pc value is {pc_value}")
#   dut._log.info(f"Resetting...")
#   await FallingEdge(dut.clk)
#
#   await reset_dut(dut)
#   await ReadOnly()
#
#   pc_value = dut.pc_o.value
#   dut._log.info(f"In the pc value is {pc_value}")
#
#   assert pc_value == 0, f"PC failed to reset"
#
#   await RisingEdge(dut.clk)
#   await ReadOnly()
#
#   pc_value = dut.pc_o.value
#   dut._log.info(f"After another cycle the pc value is {int(pc_value)}")
#   assert pc_value == 4, f"PC should have incremented to 4, but stayed at {pc_value}"



@cocotb.test()
async def test_pc_branch(dut):
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
  test_jmp_value = 1

  await reset_dut(dut)
  dut.jmp.value = 0

  for i in range(5):
    await RisingEdge(dut.clk)

  await ReadOnly()

  pc_value = dut.pc_o.value
  dut._log.info(f"Current pc value is {int(pc_value)}")

  await FallingEdge(dut.clk)

  dut.jmp.value = 1
  dut.next_pc_i.value = test_jmp_value
  dut._log.info(f"Setting PC value to {int(test_jmp_value)}")

  await RisingEdge(dut.clk)
  await ReadOnly()

  pc_value = dut.pc_o.value
  dut._log.info(f"PC value is {int(pc_value)}")

  assert pc_value == test_jmp_value, f"PC failed to jump to instruction"

  await FallingEdge(dut.clk)
  dut.jmp.value = 0

  await RisingEdge(dut.clk)
  await ReadOnly()

  pc_value = dut.pc_o.value
  dut._log.info(f"After another cycle the PC value is {int(pc_value)}")

  assert pc_value == test_jmp_value + 4, f"PC failed to increment after jump"

