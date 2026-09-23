---
name: fpga-review
description: Read simulation results the user pastes back (cocotb results.xml, Questa transcript, or waveform notes), drive the repair loop, and — on a passing run — stamp the unit as validated so it can be reused. Use after a manual Questa run.
---

# FPGA Review & Repair

Closes the generate → simulate → repair loop. The user runs the sim manually and
pastes results here.

## Steps

1. Read the pasted `results.xml` / transcript / waveform notes.
2. **If everything passed:** update `designs/<name>/unit.md` to
   `status: validated` and fill `validated: { date: <today>, tests: "<summary>" }`.
   This is the **validation gate** — the unit may now be instantiated by other
   units. Then suggest the next step (compose it into a higher unit, or, for the
   top, run `/fpga-toplevel`).
3. **If something failed:**
   - Diagnose the root cause against the approved `plan.md` and the acceptance
     criteria — RTL bug, IP misconfig, sub-unit integration, or testbench error.
   - For deep transcript/waveform analysis, delegate to the `fpga-critic`
     subagent.
   - Apply a **minimal, targeted** fix; do not rewrite broadly. Leave `unit.md`
     `status` unchanged (not validated).
   - Print the exact re-run command and wait.

Never claim to have run the simulation. Never stamp `validated` without a passing
result in hand.
