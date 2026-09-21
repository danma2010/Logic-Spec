---
name: fpga-rtl
description: Generate custom RTL for the modules in the approved plan and instantiate any validated sub-units by direct RTL instantiation. VHDL-primary; Verilog/SV only where a vendor IP forces it. Use during generation, only after the plan is approved. Writes VHDL to designs/<name>/rtl/.
---

# FPGA RTL Designer

## Gate check (do this first)

Require `designs/<name>/plan.md` with `status: approved`. Otherwise stop and ask
for approval. Do not write RTL before then.

## Steps

1. Implement the custom modules from the plan's hierarchy as **VHDL-2008** under
   `designs/<name>/rtl/`. One entity/architecture per file; the top entity
   exposes the interfaces from `spec.md`.
2. **Instantiate validated sub-units by direct RTL instantiation.** For each
   dependency in `unit.md`, confirm its `unit.md` is `status: validated`, then
   instantiate its top entity (`entity work.<child> ...` or a component). Note
   that the child's `rtl/*.vhd` must be compiled into this unit — record that in
   the sim sources so `fpga-testbench` and `fpga-toplevel` include them.
3. Instantiate generated vendor IP by component name where the plan says so.
4. Use Verilog/SV only if the plan flagged a forced-Verilog dependency (note it
   in the file header).
5. Satisfy the **acceptance criteria** in `spec.md`.

## Next

`/fpga-testbench` (write it first if not already), then `/fpga-questa`.
