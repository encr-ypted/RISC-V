import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ReadOnly


async def reset_cpu(dut):
  """Pulse the reset signal."""
  dut.rst.value = 1
  await RisingEdge(dut.clk)
  dut.rst.value = 0
  # await RisingEdge(dut.clk)
  dut._log.info("CPU Reset Complete. Booting...")


@cocotb.test()
async def test_cpu_first_program(dut):
  """Run the CPU and verify it executes the ADDI/ADD program."""
  # 1. Start the Clock
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  # 2. Reset the CPU
  await reset_cpu(dut)
  await ReadOnly()
  pc = int(dut.current_pc_value.value)
  inst = hex(int(dut.instruction.value))
  dut._log.info(f"Initialised values: PC = {pc}, Executing = {inst}")


  # 3. Let the CPU run for 10 clock cycles
  # Our program is only 4 instructions, so 10 cycles is plenty.
  for i in range(10):
    await RisingEdge(dut.clk)
    await ReadOnly()

    # Log the PC and Instruction just to see what's happening
    pc = int(dut.current_pc_value.value)
    inst = hex(int(dut.instruction.value))
    dut._log.info(f"Cycle {i + 1}: PC = {pc}, Executing = {inst}")

  # 4. The "Magic" Check
  # Cocotb allows us to peek INSIDE the modules!
  # Let's check if register x3 actually got the value 12 (5 + 7)
  x1_val = int(dut.reg_file.reg_file[1].value)
  x2_val = int(dut.reg_file.reg_file[2].value)
  x3_val = int(dut.reg_file.reg_file[3].value)

  dut._log.info(f"Final Register States: x1={x1_val}, x2={x2_val}, x3={x3_val}")

  assert x1_val == 5, f"x1 should be 5, but was {x1_val}"
  assert x2_val == 7, f"x2 should be 7, but was {x2_val}"
  assert x3_val == 12, f"x3 should be 12 (5+7), but was {x3_val}"

  dut._log.info("SUCCESS! The CPU executed the program perfectly.")
