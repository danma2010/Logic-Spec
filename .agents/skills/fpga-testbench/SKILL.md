---
name: fpga-testbench
description: Write the test plan FIRST, then the testbench from the acceptance criteria — cocotb (Python) on Questa by default, UVM only if the plan flags it. Generates the test_plan.md, cocotb tests (test-by-test), and the manual Questa run Makefile. Use after the plan is approved; ideally before or alongside the RTL (verification-first).
---

# FPGA Testbench (verification-first)

## Gate check (do this first)

Require `designs/<name>/plan.md` with `status: approved`. Otherwise stop.

## Steps

1. **Test Plan (ahead of testing):** Generate a `designs/<name>/test_plan.md`. The testing of the unit must be done as a collection of tests. Each test in the plan must validate specific features from the unit's functionality, and have clear criteria for a pass.
2. **Implement Tests:** Turn each **acceptance criterion** and test from the test plan into a cocotb test under `designs/<name>/tb/`. Write these before/with the RTL.
3. Drive the DUT top through its ports; a VHDL top talks to cocotb via Questa's FLI. Vendor/forced-Verilog IP inside the DUT is simulated by Questa.
4. **Hierarchy:** For a `composite`/`top` unit, this is an **integration test**: include every instantiated sub-unit's `rtl/*.vhd` in the compile order (sub-units first), reading the dependency list from `architecture.md`. Sub-units keep their own standalone validation; this test checks their composition.
5. **Test-by-test Execution:** Emit `designs/<name>/tb/Makefile` from `templates/questa/Makefile`. Fill `TOPLEVEL`, `MODULE`, the full `VHDL_SOURCES` (subtree included), and `-L <vendor_lib>`. Ensure the Makefile supports running tests individually (e.g., passing a specific test name).
6. Use SV/UVM only if the plan flags it (emit `run_sim.tcl` instead).

## Manual run (print; do not run)

```
cd designs/<name>/tb && make          # run all cocotb tests on Questa
# OR run test-by-test:
cd designs/<name>/tb && make TESTCASE=<test_name>
```

Results: `results.xml` + transcript. Bring them to `/fpga-review`.

## Next

`/fpga-questa` to (re)generate sim scripts and the one-time lib compile, then run manually test-by-test or full suite and bring results to `/fpga-review`.


## Status Tracking (design_log.md)

At the end of your execution, you must update `designs/<name>/design_log.md`. Prepend the new status data to the TOP of the file. Include the current cycle version number (determine the current cycle from the existing file and increment if starting a new design round/iteration), the stage you just completed, the overall design status, and the status of the test plan.
