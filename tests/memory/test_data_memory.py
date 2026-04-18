import pytest
import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ReadOnly
from cocotb.clock import Clock


@cocotb.test()
async def test_write_read(dut):
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
  dut.memory[0].value = 0xCCCCCCCC

  dut.we_i.value = 0
  dut.be_i.value = 0
  dut.addr_i.value = 0
  dut.data_i.value = 0
  await RisingEdge(dut.clk)

  dut.we_i.value = 1
  dut.be_i.value = 0b1111
  dut.addr_i.value = 0
  dut.data_i.value = 0xDEADBEEF
  await RisingEdge(dut.clk)

  dut.we_i.value = 0
  dut.be_i.value = 0
  await RisingEdge(dut.clk)
  await ReadOnly()

  result = dut.data_o.value
  dut._log.info(f"Read value: {hex(result)}")

  assert result == 0xDEADBEEF, f"Expected 0xDEADBEEF, got {hex(result)}"

# @pytest.mark.parametrize("mask, data, expected", [
#   (0b0000, 0xAAAAAAAA, 0xFFFFFFFF),
#   (0b0001, 0xAAAAAAAA, 0xFFFFFFAA),
#   (0b0010, 0xAAAAAAAA, 0xFFFFAAFF),
#   (0b0100, 0xAAAAAAAA, 0xFFAAFFFF),
#   (0b1000, 0xAAAAAAAA, 0xAAFFFFFF),
#   (0b1111, 0xAAAAAAAA, 0xAAAAAAAA),
# ])

async def write_read_check(dut, addr, data, be):
  await FallingEdge(dut.clk)
  dut.we_i.value = 1
  dut.be_i.value = be
  dut.addr_i.value = addr
  dut.data_i.value = data
  await RisingEdge(dut.clk)

  dut.we_i.value = 0
  await RisingEdge(dut.clk)
  await ReadOnly()

  return dut.data_o.value.to_unsigned()


@cocotb.test()
async def test_byte_enable_write(dut):
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  dut.we_i.value = 0
  await RisingEdge(dut.clk)

  base_val = 0x12345678

  for be in range(16):
    await write_read_check(dut, 0, base_val, 0xF)

    # Second: Write new data with current byte-enable
    new_data = 0xAABBCCDD
    result = await write_read_check(dut, 0, new_data, be)

    # Calculate expected result manually in Python
    expected = 0
    if (be & 0b0001):
      expected |= (new_data & 0x000000FF)
    else:
      expected |= (base_val & 0x000000FF)

    if (be & 0b0010):
      expected |= (new_data & 0x0000FF00)
    else:
      expected |= (base_val & 0x0000FF00)

    if (be & 0b0100):
      expected |= (new_data & 0x00FF0000)
    else:
      expected |= (base_val & 0x00FF0000)

    if (be & 0b1000):
      expected |= (new_data & 0xFF000000)
    else:
      expected |= (base_val & 0xFF000000)

    # Assert!
    assert result == expected, f"Failed at BE={bin(be)}: Expected {hex(expected)}, got {hex(result)}"

  cocotb.log.info("All 16 Byte-Enable combinations passed!")

