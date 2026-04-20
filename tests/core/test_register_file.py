import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import random


async def reset_dut(dut):
  dut.rst.value = 1
  dut.we_i.value = 0
  dut.rs1_addr_i.value = 0
  dut.rs2_addr_i.value = 0
  dut.write_addr_i.value = 0
  dut.write_data_i.value = 0

  await RisingEdge(dut.clk)
  dut.rst.value = 0
  await RisingEdge(dut.clk)


@cocotb.test()
async def test_reset_behavior(dut):
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  await reset_dut(dut)

  for i in range(32):
    dut.rs1_addr_i.value = i
    await Timer(1, unit="ns")

    val = dut.rs1_o.value.integer
    assert val == 0, f"Register {i} was not 0 after reset! Got {val}"

  dut._log.info("Reset test passed: All registers are 0.")


@cocotb.test()
async def test_x0_is_hardwired_to_zero(dut):
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
  await reset_dut(dut)

  await FallingEdge(dut.clk)
  dut.we_i.value = 1
  dut.write_addr_i.value = 0
  dut.write_data_i.value = 0xDEADBEEF

  await RisingEdge(dut.clk)

  dut.we_i.value = 0
  dut.rs1_addr_i.value = 0
  await Timer(1, unit="ns")

  val = dut.rs1_o.value.integer
  assert val == 0, f"x0 was overwritten! Expected 0, got {hex(val)}"

  dut._log.info("x0 test passed: x0 is invincible.")


@cocotb.test()
async def test_basic_write_read(dut):
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
  await reset_dut(dut)

  test_reg = 15
  test_val = 0x12345678

  await FallingEdge(dut.clk)
  dut.we_i.value = 1
  dut.write_addr_i.value = test_reg
  dut.write_data_i.value = test_val
  await RisingEdge(dut.clk)

  dut.we_i.value = 0
  dut.rs1_addr_i.value = test_reg
  dut.rs2_addr_i.value = test_reg
  await Timer(1, unit="ns")

  val1 = dut.rs1_o.value.integer
  val2 = dut.rs2_o.value.integer

  assert val1 == test_val, f"rs1 read failed. Expected {hex(test_val)}, got {hex(val1)}"
  assert val2 == test_val, f"rs2 read failed. Expected {hex(test_val)}, got {hex(val2)}"

  dut._log.info(f"Basic write/read passed for register x{test_reg}.")


@cocotb.test()
async def test_simultaneous_read(dut):
  """Test reading two DIFFERENT registers at the exact same time."""
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
  await reset_dut(dut)

  # 1. Write to x1
  await FallingEdge(dut.clk)
  dut.we_i.value = 1
  dut.write_addr_i.value = 1
  dut.write_data_i.value = 0xAAAA
  await RisingEdge(dut.clk)

  # 2. Write to x2
  await FallingEdge(dut.clk)
  dut.write_addr_i.value = 2
  dut.write_data_i.value = 0xBBBB
  await RisingEdge(dut.clk)

  # Turn off writes
  dut.we_i.value = 0

  # 3. Read x1 and x2 simultaneously
  dut.rs1_addr_i.value = 1
  dut.rs2_addr_i.value = 2
  await Timer(1, unit="ns")

  val1 = dut.rs1_o.value.integer
  val2 = dut.rs2_o.value.integer

  assert val1 == 0xAAAA, f"Expected x1=0xAAAA, got {hex(val1)}"
  assert val2 == 0xBBBB, f"Expected x2=0xBBBB, got {hex(val2)}"

  dut._log.info("Simultaneous dual-port read passed.")


