---
name: fpga-ip
description: Resolve abstract IP requirements to concrete vendor IP and generate the Vivado (Xilinx) or Platform Designer (Altera) Tcl that configures and generates them. Use during generation, only after the plan is approved. Writes tcl/build_ip.tcl for the user to run — never runs Vivado itself (except under fpga-auto).
---

# FPGA IP-Core

## Gate check (do this first)

Require `spec/plan.md` with `status: approved`. Otherwise **stop** and
tell the user to approve the plan. Do not write any files.

## Steps

1. From `spec/plan.md`, take each resolved IP. Prefer a parameterizable primitive
   (e.g. Xilinx XPM macros) when the unit exposes the IP's size as a generic —
   XPMs need no generation step, only `-L xpm` in simulation. Otherwise use a
   configured core (`create_ip`, or Altera `.ip`/`.qsys`).
2. For configured cores emit `tcl/build_ip.tcl` from
   `{{LOGIC_SPEC}}/templates/vivado/build_ip.tcl`: `create_project -in_memory -part <part>` →
   `create_ip … -dir $SCRIPT_DIR/ip` → `set_property CONFIG.* …` →
   `generate_target all`. Paths come from the script's own location; `part`
   from `spec/architecture.md`. Altera: the `qsys-generate`/`ip-generate` equivalent.
3. Record each IP's `.xci` path so `fpga-testbench`, `fpga-toplevel` and
   `fpga-auto` read it (`tcl/ip/<module>/<module>.xci`).
4. **Do not run Vivado.** Print the command and wait:

   ```
   vivado -mode batch -source tcl/build_ip.tcl
   ```

## Next

`fpga-blockdesign` (only if the plan wires IP in a BD), then `fpga-rtl`.

## Design log

Prepend an entry to `spec/design_log.md` (format:
`{{LOGIC_SPEC}}/templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
