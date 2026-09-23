---
name: fpga-testbench
description: Write the testbench FIRST from the acceptance criteria — cocotb (Python) on Questa by default, UVM only if the plan flags it. Generates the cocotb tests and the manual Questa run Makefile. Use after the plan is approved; ideally before or alongside the RTL (verification-first).
---

# FPGA Testbench (verification-first)

## Gate check (do this first)

Require `designs/<name>/plan.md` with `status: approved`. Otherwise stop.

## Steps

1. Turn each **acceptance criterion** in `spec.md` into a cocotb test under
   `designs/<name>/tb/`. Write these before/with the RTL.
2. Drive the DUT top through its ports; a VHDL top talks to cocotb via Questa's
   FLI. Vendor/forced-Verilog IP inside the DUT is simulated by Questa.
3. **Hierarchy.** For a `composite`/`top` unit, this is an **integration test**:
   include every instantiated sub-unit's `rtl/*.vhd` in the compile order
   (sub-units first), reading the dependency list from `unit.md`. Sub-units keep
   their own standalone validation; this test checks their composition.
4. Emit `designs/<name>/tb/Makefile` from `templates/questa/Makefile`, filling
   `TOPLEVEL`, `MODULE`, the full `VHDL_SOURCES` (subtree included), and
   `-L <vendor_lib>`.
5. Use SV/UVM only if the plan flags it (emit `run_sim.tcl` instead).

## Manual run (print; do not run)

```
cd designs/<name>/tb && make          # cocotb on Questa
```

Results: `results.xml` + transcript. Bring them to `/fpga-review`.

## Next

`/fpga-questa` to (re)generate sim scripts and the one-time lib compile, then run
manually and bring results to `/fpga-review`.
