---
name: fpga-auto
description: Opt-in automatic mode for the verify loop. Only when the user explicitly invokes it, the agent runs tools/run_tests.sh (test by test, report) and an out-of-context synthesis check itself and iterates generate → sim → repair without manual paste-back. Bounded and guard-railed; asks the user to confirm before stamping a unit validated. Never runs implementation, bitstream or hardware.
---

# FPGA Auto Mode (opt-in)

The **only** mode allowed to execute EDA tools; the rest of the framework is
manual (CLAUDE.md rule 6).

## Preconditions (stop if unmet)

- `plan.md` and `testplan.md` are `status: approved` (gates 1 and 2 still apply).
- RTL and the cocotb testbench exist; `python3 tools/make_report.py --check
  designs/<unit>` prints `TESTPLAN OK`.
- For a `composite`/`top`, every dependency is `status: validated`.
- A shell is available and the simulator (and Vivado, for the synth check) are
  on `PATH`; vendor libs are compiled if the unit uses them. If not, stay in
  manual mode and say so.

## Scope (hard limits)

- Runs **functional simulation** (`tools/run_tests.sh`) and an **OOC synthesis
  check** (`tools/run_synth_check.sh`) only.
- **Never** runs implementation, place/route, bitstream, or anything touching
  hardware.
- Reports only **real** results from actual runs. Never fabricates a verdict.

## The loop (cap: 5 iterations by default)

Announce the commands, then iterate:

1. **Test.** `bash tools/run_tests.sh <unit>` (default configuration). Read
   `sim/test_report.md`.
2. **On FAIL:** take the first failing `must` test in plan order; diagnose
   against its pass criterion (delegate deep reads to `fpga-critic`).
   - Clear root cause + a **minimal** fix that does **not** change the unit's
     interface or the test plan → apply, log, re-run that test
     (`run_tests.sh <unit> questa <ID>`), then the full suite.
   - Otherwise → **stop and hand back**.
3. **On report PASS:** write `designs/<unit>/build/synth_sources.tcl` in the
   `templates/vivado/run_sources.tcl` format (paths relative to the file,
   sub-units bottom-up, `read_ip` for generated IP), then
   `bash tools/run_synth_check.sh <unit>` (TOP/PART from `architecture.md`).
   - `SYNTH FAIL` from an RTL synthesizability issue → minimal fix, back to 1.
   - Timing/constraint/ambiguous failure → stop and hand back.
4. **Done** when the report verdict is PASS and `SYNTH PASS`.

## Stop and hand back when

- the iteration cap is reached;
- the same failure repeats after a fix;
- the root cause is ambiguous, or the fix would change ports or the test plan;
- the failure is non-functional (timing/resource).

Summarize what happened and the next step; do not keep looping.

## Logging

Append every command, verdict and applied fix to
`designs/<unit>/sim/auto_log.md` (one line per action, timestamped).

## Confirmation before validate (required)

Present the summary (report verdict, synth result, fixes, log path) and **ask
the user to confirm.** Only then apply gate 3 exactly as `fpga-review` does
(`status: validated`, `validated: {date, tests, report}`).

## Design log

Prepend an entry to `designs/<name>/design_log.md` (format:
`templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
