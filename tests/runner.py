import os
from pathlib import Path
from cocotb_tools.runner import get_runner


PROJ_PATH = Path(__file__).resolve().parent.parent
RTL_DIR = PROJ_PATH / "rtl"
TESTS_DIR = PROJ_PATH / "tests"

INTEL_LIBS = [
    "-L", "altera_mf_ver", "-L", "lpm_ver", "-L", "sgate_ver",
    "-L", "altera_lnsim_ver", "-L", "cyclonev_ver",
    "-L", "altera_mf", "-L", "lpm", "-L", "sgate",
    "-L", "altera_lnsim", "-L", "cyclonev"
  ]

def run_module_test(hdl_toplevel, source_files, test_module, gui=False):
  sim = os.getenv("SIM", "questa")
  runner = get_runner(sim)

  build_dir = PROJ_PATH / "sim_build" / hdl_toplevel

  runner.build(
    sources=source_files,
    hdl_toplevel=hdl_toplevel,
    always=True,  # Force re-compilation
    build_dir=build_dir,
  )

  runner.test(
    hdl_toplevel=hdl_toplevel,
    test_module=test_module,
    test_args=INTEL_LIBS,
    build_dir=build_dir,
    waves=True,
    gui=gui
  )



def test_data_memory_runner(gui=False):
  run_module_test(
    hdl_toplevel="data_memory",
    source_files=[RTL_DIR / "memory" / "data_memory.sv"],
    test_module= "memory.test_data_memory",
    gui=gui
  )

def test_instruction_memory_runner(gui=False):
  run_module_test(
    hdl_toplevel="instruction_memory",
    source_files=[RTL_DIR / "memory" / "instruction_memory.sv"],
    test_module= "memory.test_instruction_memory",
    gui=gui
  )

def test_pc_runner(gui=False):
  run_module_test(
    hdl_toplevel="pc",
    source_files=[RTL_DIR / "core" / "pc.sv"],
    test_module= "core.test_pc",
    gui=gui
  )

def test_register_file_runner(gui=False):
  run_module_test(
    hdl_toplevel="register_file",
    source_files=[RTL_DIR / "core" / "register_file.sv"],
    test_module= "core.test_register_file",
    gui=gui
  )


if __name__ == "__main__":
  # test_data_memory_runner()
  # test_instruction_memory_runner()
  # test_pc_runner()
  test_register_file_runner()