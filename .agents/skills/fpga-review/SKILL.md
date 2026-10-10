---
name: fpga-review
description: Read simulation results the user pastes back (cocotb results.xml, Questa transcript, or waveform notes), drive the repair loop, and — on a passing run — stamp the unit as validated so it can be reused. In the automatic flow, create a test report of which tests passed or failed. Use after a manual Questa run.
---

# FPGA Review & Repair

Closes the generate → simulate → repair loop. The user runs the sim manually and
pastes results here.

## Steps

1. Read the pasted `results.xml` / transcript / waveform notes.
2. **Generate Test Report:** Create an automatic result report at `designs/<name>/test_report.md` listing exactly which tests (from the `test_plan.md`) passed and which failed based on their pass criteria.
3. **If everything passed:** update `designs/<name>/architecture.md` to
   `status: validated` and fill `validated: { date: <today>, tests: "<summary>" }`.
   This is the **validation gate** — the unit may now be instantiated by other
   units. Then suggest the next step (compose it into a higher unit, or, for the
   top, run `/fpga-toplevel`).
4. **If something failed:**
   - Diagnose the root cause against the approved `plan.md` and the acceptance
     criteria — RTL bug, IP misconfig, sub-unit integration, or testbench error.
   - For deep transcript/waveform analysis, delegate to the `fpga-critic`
     subagent.
   - Apply a **minimal, targeted** fix; do not rewrite broadly. Leave `architecture.md`
     `status` unchanged (not validated).
   - Print the exact re-run command and wait.

Never claim to have run the simulation. Never stamp `validated` without a passing
result in hand.


## Status Tracking (design_log.md)

At the end of your execution, you must update `designs/<name>/design_log.md`. Prepend the new status data to the TOP of the file. Include the current cycle version number (determine the current cycle from the existing file and increment if starting a new design round/iteration), the stage you just completed, the overall design status, and the status of the test plan.
