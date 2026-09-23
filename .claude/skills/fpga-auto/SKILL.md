---
name: fpga-auto
description: Opt-in automatic mode for the verify loop. When explicitly invoked, Claude Code runs the prepared functional simulation (any cocotb simulator) and an out-of-context synthesis check itself, via Bash, and iterates generate → sim → repair without manual paste-back. Bounded and guard-railed; stops for user confirmation before stamping a unit validated. Does not run implementation, bitstream, or hardware.
---

# FPGA Auto Mode (opt-in)

Runs the verify loop for a unit automatically inside Claude Code. This is the
**only** mode allowed to execute EDA tools; the rest of the framework is manual.

## Preconditions (stop if unmet)

- `designs/<unit>/unit.md` exists and `designs/<unit>/plan.md` is
  `status: approved` (plan gate still applies).
- RTL and a cocotb testbench exist (`/fpga-rtl`, `/fpga-testbench` have run).
- For a `composite`, every dependency in `unit.md` is `status: validated`.
- `Bash` is available and the simulator (and Vivado, for the synth check) are on
  `PATH`. If not, stay in manual mode and say so.

## Scope (hard limits)

- Runs **functional simulation** + an **out-of-context synthesis check** only.
- **Never** runs implementation, place/route, bitstream, or anything touching
  hardware — those stay manual and require explicit confirmation.
- Reports only **real** results from actual runs. Never fabricates a verdict.

## The loop (cap: 5 iterations by default)

Announce the commands you will run, then iterate:

1. **Simulate.** `bash tools/run_sim.sh <unit> [SIM]`. Read the `SIM PASS/FAIL`
   line and `sim/last_sim.log`.
2. **On SIM FAIL:** diagnose the first real failure against `plan.md` and the
   acceptance criteria (delegate deep log/waveform reads to `fpga-critic`).
   - Clear root cause + a **minimal** fix that does **not** change the unit's
     interface → apply it, log it, and re-run (next iteration).
   - Otherwise → **STOP and hand back** (see stop conditions).
3. **On SIM PASS:** write `designs/<unit>/build/synth_sources.tcl` — `read_vhdl`
   for the unit's `rtl/*.vhd` and each validated sub-unit's `rtl/` (bottom-up),
   plus `read_ip`/`generate_target` for vendor IP — then
   `bash tools/run_synth_check.sh <unit> [PART]`.
   - `SYNTH FAIL` from an RTL synthesizability issue → minimal fix, re-run.
   - `SYNTH FAIL` from timing/constraints/ambiguous, or `SYNTH PASS` → go to done.
4. **Done (SIM PASS + SYNTH PASS):** stop the loop.

## Stop and hand back to the user when

- The iteration cap is reached without a clean result.
- The same failure repeats after a fix (no progress).
- The root cause is ambiguous, or the only fix would change the unit's
  **interface/ports**.
- The failure is non-functional (timing/resource) beyond this mode's scope.

Summarize what happened and what you'd do next; do not keep looping.

## Logging

Append every command, verdict, and applied fix to
`designs/<unit>/sim/auto_log.md` (one line per action), so the run is auditable.

## Confirmation before validate (required)

When the loop finishes clean, **do not stamp `validated` automatically.** Present
the summary (tests passed, synth clean, fixes applied, log path) and **ask the
user to confirm.** Only on confirmation set `unit.md` → `status: validated` and
fill `validated: { date, tests }`. Without confirmation, leave the status as is.
