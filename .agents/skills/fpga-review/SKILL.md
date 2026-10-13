---
name: fpga-review
description: Read the per-test report (sim/test_report.md, or pasted results), repair failing tests one by one against their pass criteria, and — when every must test passes on current sources — apply gate 3 and stamp the unit validated in architecture.md. Use after the user has run tools/run_tests.sh.
---

# FPGA Review & Repair — gate 3

Closes the generate → simulate → repair loop.

## Steps

1. Read `designs/<name>/sim/test_report.md` (+ `sim/tests/<ID>.log`). If the
   user pasted `results.xml`/a transcript instead, use it, but ask for a
   `tools/run_tests.sh` run before validating.
2. **Failing tests, in plan order.** For each FAIL / ERROR / STALE:
   - diagnose against that test's pass criterion in `testplan.md`, the AC it
     covers, and `plan.md` — RTL bug, IP misconfig, sub-unit integration,
     testbench bug, or sim setup;
   - for deep log/waveform analysis delegate to `fpga-critic`;
   - apply a **minimal, targeted** fix. Never weaken a pass criterion or
     delete a test to get a pass — that is a test-plan change (back to
     `pending`, user approval);
   - if the unit was `validated`, set it back to `generated` (see AGENTS.md);
   - print the re-run command for that test and wait:
     `bash tools/run_tests.sh <name> questa <ID>`.
3. **Validation (gate 3).** Only when the report's verdict is
   `PASS — meets the validation gate` from a **full, default-configuration**
   run (no `MAKE_ARGS`, no STALE rows): every `must` test PASS, every
   non-passing `should` test waived in `testplan.md`, test plan approved. Then
   set in `architecture.md`:
   `status: validated`,
   `validated: { date: <today>, tests: "<n>/<n> must PASS", report: sim/test_report.md }`.
   Suggest the next step (compose into a higher unit, or `fpga-toplevel`).

Never claim to have run a simulation. Never stamp `validated` without that
report in hand.

## Design log

Prepend an entry to `designs/<name>/design_log.md` (format:
`templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
