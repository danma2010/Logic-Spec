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
   correct — sources, `TOPLEVEL`, `MODULE`, `-L <vendor_lib>`. SV/UVM path:
   emit `designs/<name>/sim/run_sim.tcl` from `templates/questa/run_sim.tcl`.
3. **Do not run Questa.** Print the exact manual commands:

   ```
   # one-time, per Questa version:
   vivado -mode batch -source designs/<name>/sim/compile_simlib.tcl

   # each run (cocotb):
   cd designs/<name>/tb && make

   # or (SV/UVM):
   vsim -c -do designs/<name>/sim/run_sim.tcl
   ```

4. Tell the user where results appear (`results.xml`, `transcript`) and to paste
   them into `/fpga-review`.
