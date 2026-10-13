---
name: fpga-rtl
description: Generate custom VHDL-2008 RTL for the modules in the approved plan, including the unit's top entity, and instantiate validated sub-units by direct RTL instantiation. Verilog/SV only where a vendor IP forces it. Use during generation, only after the plan is approved. Writes designs/<name>/rtl/ and sets the unit status to generated.
---

# FPGA RTL Designer

## Gate check (do this first)

Require `designs/<name>/plan.md` with `status: approved`. Otherwise stop.

## Steps

1. Implement the plan's modules as **VHDL-2008** under `designs/<name>/rtl/`,
   one entity per file. The unit's top entity is `rtl/<top>.vhd` (`top:` in
   `architecture.md`) and exposes exactly the `ports` of the manifest; make
   sizes generics where the architecture lists them.
2. **Sub-units:** for each `dependencies` entry confirm its `architecture.md`
   is `status: validated`, then instantiate its `top` entity
   (`entity work.<child_top>`). Its `rtl/*.vhd` (and IP) are compiled into this
   unit — record the compile order (children first) for `fpga-testbench`,
   `fpga-toplevel` and `fpga-auto`.
3. Instantiate vendor IP as the plan says: XPM macros via
   `library xpm; use xpm.vcomponents.all;`, generated cores by component name,
   a BD by its `<name>_bd_wrapper`.
4. Verilog/SV only for a forced-Verilog dependency flagged in the plan (note it
   in the file header).
5. Satisfy the acceptance criteria in `architecture.md`.

## Status

- First RTL written → set `architecture.md` `status: generated`.
- Editing RTL of a `validated` unit → set `status: generated`, clear
  `validated: {}`, and tell the user which parent units now need re-validation.

## Next

`fpga-testbench` (if not already written), then `fpga-questa`.

## Design log

Prepend an entry to `designs/<name>/design_log.md` (format:
`templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
