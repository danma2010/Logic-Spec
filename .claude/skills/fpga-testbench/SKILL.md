---
name: fpga-testbench
description: Write the testbench FIRST from the acceptance criteria — cocotb (Python) on Questa by default, UVM only if the plan flags it. Generates the cocotb tests and the manual Questa run Makefile. Use after the plan is approved; ideally before or alongside the RTL (verification-first).
---

# FPGA Testbench (verification-first)

## Gate check (do this first)

Require `designs/<name>/plan.md` with `status: approved`. Otherwise stop.

## Steps

1. Turn each **acceptance criterion** in `spec.md` into a cocotb test coroutine
   under `designs/<name>/tb/` (e.g. `test_<top>.py`). Write these **before or
   alongside** the RTL — the criteria are the gate the RTL must pass.
2. Drive the DUT top through its ports; the VHDL top talks to cocotb via
   Questa's FLI. Vendor/forced-Verilog IP inside the DUT is simulated by Questa
   and needs no special handling in the test.
3. Emit `designs/<name>/tb/Makefile` from `templates/questa/Makefile`, filling
   `TOPLEVEL`, `MODULE`, the VHDL source glob, and the `-L <vendor_lib>` for the
   precompiled sim libraries.
4. If — and only if — the plan flags UVM, generate the SV/UVM environment and a
   `run_sim.tcl` instead of cocotb.

## Manual run (print this; do not run it)

```
cd designs/<name>/tb && make          # cocotb on Questa
```

Results land in `results.xml` (xUnit) plus the Questa transcript.

## Next

`/fpga-questa` to (re)generate sim scripts and the one-time lib compile, then run
manually and bring results to `/fpga-review`.
