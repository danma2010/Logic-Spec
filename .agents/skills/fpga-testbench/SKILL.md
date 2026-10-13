---
name: fpga-testbench
description: Write the cocotb testbench from the approved test plan — exactly one @cocotb.test per testplan.md entry, with the same function name and the pass criterion coded as assertions — plus tb/Makefile for Questa. UVM only if the plan flags it. Use after gate 2; ideally before or alongside the RTL (verification-first).
---

# FPGA Testbench (verification-first)

## Gate check (do this first)

Require `designs/<name>/plan.md` **and** `designs/<name>/testplan.md`, both
`status: approved`. Otherwise stop and name the missing gate.

## Steps

1. For every row of `testplan.md` write one `@cocotb.test()` named exactly as
   its `Function` column, in `designs/<name>/tb/test_<name>.py`. Put the test
   ID and pass criterion in the docstring; code the criterion as assertions with
   messages that state expected vs. actual. No extra tests outside the plan
   (add them to the plan first).
2. Drive the DUT through the unit's `top` ports (VHDL top ↔ cocotb via Questa
   FLI/VHPI). Use reusable drivers/monitors; sample handshakes **at** the clock
   edge (drive after `RisingEdge`, decide on the values that were present at
   the edge — e.g. use `ReadOnly()` before sampling), so backpressure can't
   duplicate or drop beats in the model.
3. Use `random` seeded by cocotb (no private seeds) so `RANDOM_SEED`
   reproduces a run.
4. **Hierarchy:** for a `composite`/`top`, this is an integration test: compile
   every sub-unit's `rtl/*.vhd` first (bottom-up, from `dependencies`).
5. Emit `designs/<name>/tb/Makefile` from `templates/questa/Makefile`: the
   **default** configuration must use the unit's real `top` and real IP models
   (this is what gate 3 accepts). A behavioural fast loop is allowed only as an
   opt-in make variable (e.g. `FAST=1`).
6. Lint: `python3 tools/make_report.py --check designs/<name>` → `TESTPLAN OK`
   (now also checks every planned test exists in `tb/`).
7. SV/UVM only if the plan flags it (emit `sim/run_sim.tcl` via `fpga-questa`).

## Manual run (print; do not run)

```
bash tools/run_tests.sh <name>             # test by test → sim/test_report.md
```

## Next

`fpga-questa`, then the user runs the tests and comes back to `fpga-review`.

## Design log

Prepend an entry to `designs/<name>/design_log.md` (format:
`templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
