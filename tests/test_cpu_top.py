import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly


async def reset_cpu(dut):
  """Pulse the reset signal."""
  dut.rst.value = 1
  await RisingEdge(dut.clk)
  dut.rst.value = 0
  # await RisingEdge(dut.clk)
  dut._log.info("CPU Reset Complete. Booting...")


@cocotb.test()
async def test_pipeline_hazards(dut):
  """Run the pipeline stress test."""

  # 1. Start the Clock
  cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

  # 2. Reset the CPU
  await reset_cpu(dut)

  # 3. Run the clock for 15 cycles (enough to fill and drain the 5-stage pipe)
  for i in range(15):
    await RisingEdge(dut.clk)
    await ReadOnly()  # Wait for combinational logic to settle

    # Read the PC at the 3 main stages to watch the flow
    if_pc = int(dut.if_pc.value)
    id_pc = int(dut.id_pc.value)
    ex_pc = int(dut.ex_pc.value)

    # Log the flow
    dut._log.info(f"Cycle {i + 1} | IF_PC: {if_pc:2} | ID_PC: {id_pc:2} | EX_PC: {ex_pc:2}")

  # 4. Final Register Assertions
  # We use .integer to safely cast the value
  x1_val = dut.reg_file.reg_file[1].value.to_unsigned()
  x2_val = dut.reg_file.reg_file[2].value.to_unsigned()
  x3_val = dut.reg_file.reg_file[3].value.to_unsigned()
  x4_val = dut.reg_file.reg_file[4].value.to_unsigned()
  x5_val = dut.reg_file.reg_file[5].value.to_unsigned()

  dut._log.info(f"Final States: x1={x1_val}, x2={x2_val}, x3={x3_val}, x4={x4_val}, x5={x5_val}")

  # Verify the Math and the Hazards
  assert x1_val == 5, f"Expected x1=5, got {x1_val}"
  assert x2_val == 7, f"Expected x2=7, got {x2_val}"
  assert x3_val == 12, f"EX-to-EX Forwarding FAILED! Expected x3=12, got {x3_val}"
  assert x4_val == 12, f"Memory Load FAILED! Expected x4=12, got {x4_val}"
  assert x5_val == 17, f"Load-Use Stall/Forwarding FAILED! Expected x5=17, got {x5_val}"

  dut._log.info("SUCCESS! The Pipelined CPU handled all hazards correctly!")

