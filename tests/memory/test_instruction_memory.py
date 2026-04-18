import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ReadOnly, ReadWrite
from cocotb.clock import Clock
import math


@cocotb.test()
async def test_instruction_memory_stress(dut):
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  dut.addr_i.value = 0

  for i in range(1024):
    dut.memory[i].value = i

  await RisingEdge(dut.clk)

  for i in range(1024):
    await FallingEdge(dut.clk)
    dut.addr_i.value = i * 4

    await RisingEdge(dut.clk)
    await ReadOnly()

    actual_val = int(dut.data_o.value)
    assert actual_val == i, f"Failed at word {i} (addr {i*4}). Expected {i}"

    if i % 256 == 0:
      dut._log.info(f"Successfully read {actual_val} (word {i}) at Address {i * 4}")



@cocotb.test()
async def test_riscv_program_fetch(dut):
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  program = [
    0x00000293,  # addi x5, x0, 0
    0x00128293,  # addi x5, x5, 1
    0x00228293,  # addi x5, x5, 2
    0x00000013,  # nop
  ]

  for i, instruction in enumerate(program):
    dut.memory[i].value = instruction

  await RisingEdge(dut.clk)

  for i, expected_instruction in enumerate(program):
    await FallingEdge(dut.clk)
    dut.addr_i.value = i * 4

    await RisingEdge(dut.clk)
    await ReadOnly()

    actual_val = int(dut.data_o.value)
    assert actual_val == expected_instruction, f"Program fetch failed at address {i*4}!"

    dut._log.info(f"Fetched Instruction: {hex(actual_val)} from Address {hex(i * 4)}")


@cocotb.test()
async def test_byte_alignment(dut):
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  dut.memory[0].value = 0xAAAAAAAA  # Word 0
  dut.memory[1].value = 0xBBBBBBBB  # Word 1

  await RisingEdge(dut.clk)

  test_cases = [
    (0b000, 0xAAAAAAAA),
    (0b001, 0xAAAAAAAA),
    (0b010, 0xAAAAAAAA),
    (0b011, 0xAAAAAAAA),
    (0b100, 0xBBBBBBBB),
    (0b101, 0xBBBBBBBB),
    (0b110, 0xBBBBBBBB),
    (0b111, 0xBBBBBBBB),
  ]

  for address, expected_val in test_cases:
    await FallingEdge(dut.clk)
    dut.addr_i.value = address

    await RisingEdge(dut.clk)
    await ReadOnly()

    actual_val = int(dut.data_o.value)

    # The crucial Assert!
    assert actual_val == expected_val, \
      f"Alignment failure at address {address} ({bin(address)}). " \
      f"Expected {hex(expected_val)}, got {hex(actual_val)}"

    dut._log.info(f"Address {address} ({bin(address)}) correctly mapped to {hex(actual_val)}")
