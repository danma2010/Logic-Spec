---
name: fpga-questa
description: Prepare and explain the Questa simulation flow for a unit — confirm tb/Makefile, write sim/RUN.md, emit sim/run_sim.tcl for the SV/UVM path, and point to the shared one-time vendor-library compile — then hand the user the exact commands (run_tests.sh). Use after RTL and testbench exist. Never runs Questa itself (except under fpga-auto).
---

# FPGA Questa Scripts

## Gate check

Require `spec/plan.md` and `spec/testplan.md` with `status: approved`.

## Steps

1. **Vendor libs (shared, once per tool version).** Libraries live in
   `{{LOGIC_SPEC}}/simlibs/questa/`, built by `{{LOGIC_SPEC}}/tools/compile_simlib.tcl`. Do not emit a
   per-unit copy.
2. **cocotb run (default).** Check `tb/Makefile`: absolute
   source paths, sub-units first, `TOPLEVEL` = the unit's `top`, `MODULE`,
   vendor libs picked up from `{{LOGIC_SPEC}}/simlibs/questa/modelsim.ini`.
3. **SV/UVM path** (only if the plan flags UVM): emit
   `sim/run_sim.tcl` from `{{LOGIC_SPEC}}/templates/questa/run_sim.tcl`
   (set its `LOGIC_SPEC` default to `{{LOGIC_SPEC}}`).
4. Write `sim/RUN.md` with the unit-specific commands below.
5. **Do not run Questa.** Print the commands (run from the design folder):

   ```
   # one-time, per Vivado/Questa version (all units):
   QUESTA_BIN=<questa>/bin vivado -mode batch -source {{LOGIC_SPEC}}/tools/compile_simlib.tcl

   # if the unit has generated IP:
   vivado -mode batch -source tcl/build_ip.tcl

   # lint the test plan (no EDA):
   python3 {{LOGIC_SPEC}}/tools/make_report.py --check .

   # run the tests one by one + report:
   bash {{LOGIC_SPEC}}/tools/run_tests.sh .
   bash {{LOGIC_SPEC}}/tools/run_tests.sh . questa T02          # one test
   RANDOM_SEED=<n> bash {{LOGIC_SPEC}}/tools/run_tests.sh . questa T02   # reproduce

   # SV/UVM path only:
   vsim -c -do sim/run_sim.tcl
   ```

6. Tell the user the result is `sim/test_report.md` (per-test
   PASS/FAIL, seeds, logs in `sim/tests/`) and to bring it to `fpga-review`.

## Design log

Prepend an entry to `spec/design_log.md` (format:
`{{LOGIC_SPEC}}/templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
