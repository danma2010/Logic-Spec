---
name: fpga-questa
description: Generate the Questa simulation scripts the user runs manually — the cocotb Makefile (default) or a plain compile+run Tcl (SV/UVM), plus the one-time vendor sim-library compile script. Use after RTL and testbench exist. Never runs Questa itself.
---

# FPGA Questa Scripts

## Steps

1. **One-time vendor libs.** Emit `designs/<name>/sim/compile_simlib.tcl` from
   `templates/questa/compile_simlib.tcl`. This builds the Questa-usable vendor
   simulation libraries and only needs to run once per tool version.
2. **Run script.** Default: ensure `designs/<name>/tb/Makefile` (cocotb) is
   correct — sources, `TOPLEVEL`, `MODULE`, `-L <vendor_lib>`. Ensure the Makefile supports `TESTCASE` for test-by-test runs. SV/UVM path:
   emit `designs/<name>/sim/run_sim.tcl` from `templates/questa/run_sim.tcl`.
3. **Do not run Questa.** Print the exact manual commands. Remind the user to run the tests in the test plan test-by-test or as a full suite:

   ```
   # one-time, per Questa version:
   vivado -mode batch -source designs/<name>/sim/compile_simlib.tcl

   # each run (cocotb, all tests):
   cd designs/<name>/tb && make

   # or test-by-test (cocotb):
   cd designs/<name>/tb && make TESTCASE=<test_name>

   # or (SV/UVM):
   vsim -c -do designs/<name>/sim/run_sim.tcl
   ```

4. Tell the user where results appear (`results.xml`, `transcript`) and to paste
   them into `/fpga-review`.


## Status Tracking (design_log.md)

At the end of your execution, you must update `designs/<name>/design_log.md`. Prepend the new status data to the TOP of the file. Include the current cycle version number (determine the current cycle from the existing file and increment if starting a new design round/iteration), the stage you just completed, the overall design status, and the status of the test plan.
