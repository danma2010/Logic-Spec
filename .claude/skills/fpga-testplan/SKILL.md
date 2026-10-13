---
name: fpga-testplan
description: Break a unit into features and write testplan.md — a collection of tests T01…, each with a cocotb function name, the features and acceptance criteria AC-n it covers, a must/should priority and a measurable pass criterion — then open gate 2 (test-plan approval). Use after the plan is approved and before any testbench code.
---

# FPGA Test Plan — gate 2

## Gate check (do this first)

Require `designs/<name>/plan.md` with `status: approved`. Otherwise stop.

## Steps

1. Read the acceptance criteria `AC-n` in `architecture.md` and the
   verification strategy in `plan.md`.
2. List the unit's **features** (`F1`, `F2`, …) — behaviours worth testing in
   isolation (data path, backpressure, reset, CDC, error handling, …).
3. Write the **tests** table in `designs/<name>/testplan.md` from
   `templates/testplan.md`:
   - `ID` `T01`, `T02`, … (stable — never renumber an existing test);
   - `Function` — the cocotb test name, `t<NN>_<short_name>`;
   - `Features`, `AC` covered;
   - `Priority` — `must` (required for validation) or `should`;
   - `Pass criterion` — **measurable** (counts, bit-exactness, cycle bounds,
     dB thresholds). "Works correctly" is not a criterion.
   Every `AC-n` must be covered by at least one `must` test. Prefer one
   behaviour per test so a failure points at one feature.
4. For a composite/top: tests exercise the unit's own interface (integration);
   sub-units keep their standalone validation.
5. Lint: `python3 tools/make_report.py --check designs/<name>` must print
   `TESTPLAN OK` (before tb exists, only the plan is checked).

## The gate

Set `status: pending`, present the table and ask the user to approve. On
approval set `status: approved`. **Any** later edit (new test, changed
criterion, priority, waiver) puts it back to `pending`. Never loosen a pass
criterion to make a failing test pass.

## Next

`fpga-ip` / `fpga-blockdesign` (if the plan uses IP), `fpga-rtl`, `fpga-testbench`.

## Design log

Prepend an entry to `designs/<name>/design_log.md` (format:
`templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
