---
name: fpga-review
description: Read simulation results the user pastes back (cocotb results.xml, Questa transcript, or waveform notes) and drive the repair loop — diagnose failures and propose targeted RTL/IP/testbench fixes against the approved plan. Use after a manual Questa run.
---

# FPGA Review & Repair

This closes the generate → simulate → repair loop. The user runs the sim
manually and pastes the results here.

## Steps

1. Read the pasted `results.xml` / transcript / waveform notes.
2. **If everything passed:** say so, and suggest the next step (e.g. synthesis
   for timing/utilization — a later phase).
3. **If something failed:**
   - Diagnose the root cause against the approved `plan.md` and the acceptance
     criteria — is it an RTL bug, an IP misconfiguration, or a testbench error?
   - For deep transcript/waveform analysis, delegate to the `fpga-critic`
     subagent to keep the main context clean.
   - Propose and apply a **minimal, targeted** fix to the relevant file(s)
     under `rtl/`, `tcl/`, or `tb/`. Do not rewrite broadly.
   - Then tell the user the exact command to **re-run manually**, and wait for
     the new results.

Never claim to have run the simulation. The loop always pauses on a manual run.
