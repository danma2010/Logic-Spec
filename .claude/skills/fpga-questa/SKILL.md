---
name: fpga-questa
description: Prepare and explain the Questa simulation flow for a unit — confirm tb/Makefile, write sim/RUN.md, emit sim/run_sim.tcl for the SV/UVM path, and point to the shared one-time vendor-library compile — then hand the user the exact commands (tools/run_tests.sh). Use after RTL and testbench exist. Never runs Questa itself (except under fpga-auto).
---

# FPGA Questa Scripts

## Gate check

Require `plan.md` and `testplan.md` with `status: approved`.

## Steps

1. **Vendor libs (shared, once per tool version).** Libraries live in
   `simlibs/questa/`, built by `tools/compile_simlib.tcl`. Do not emit a
   per-unit copy.
2. **cocotb run (default).** Check `designs/<name>/tb/Makefile`: absolute
   source paths, sub-units first, `TOPLEVEL` = the unit's `top`, `MODULE`,
   vendor libs picked up from `simlibs/questa/modelsim.ini`.
3. **SV/UVM path** (only if the plan flags UVM): emit
   `designs/<name>/sim/run_sim.tcl` from `templates/questa/run_sim.tcl`.
4. Write `designs/<name>/sim/RUN.md` with the unit-specific commands below.
5. **Do not run Questa.** Print the commands:

   ```
   # one-time, per Vivado/Questa version (all units):
   QUESTA_BIN=<questa>/bin vivado -mode batch -source tools/compile_simlib.tcl

   # if the unit has generated IP:
   vivado -mode batch -source designs/<name>/tcl/build_ip.tcl

   # lint the test plan (no EDA):
   python3 tools/make_report.py --check designs/<name>

   # run the tests one by one + report:
   bash tools/run_tests.sh <name>
   bash tools/run_tests.sh <name> questa T02          # one test
   RANDOM_SEED=<n> bash tools/run_tests.sh <name> questa T02   # reproduce

   # SV/UVM path only:
   vsim -c -do designs/<name>/sim/run_sim.tcl
   ```

6. Tell the user the result is `designs/<name>/sim/test_report.md` (per-test
   PASS/FAIL, seeds, logs in `sim/tests/`) and to bring it to `fpga-review`.

## Design log

Prepend an entry to `designs/<name>/design_log.md` (format:
`templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
