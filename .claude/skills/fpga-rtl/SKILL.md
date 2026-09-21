---
name: fpga-rtl
description: Generate custom RTL for the modules in the approved plan — VHDL-primary, using Verilog/SystemVerilog only where a vendor IP forces it. Use during generation, only after the plan is approved. Writes VHDL to designs/<name>/rtl/.
---

# FPGA RTL Designer

## Gate check (do this first)

Require `designs/<name>/plan.md` with `status: approved`. Otherwise stop and ask
for approval. Do not write RTL before then.

## Steps

1. Implement the custom modules from the plan's module hierarchy as **VHDL**
   (VHDL-2008) under `designs/<name>/rtl/`. One entity/architecture per file.
2. The top entity is VHDL and exposes the interfaces from `spec.md`.
3. Instantiate generated vendor IP by its component name where the plan says so.
4. Only use Verilog/SV if the plan flagged a forced-Verilog dependency — and
   note it in the file header.
5. Write RTL that satisfies the **acceptance criteria** in `spec.md`; those are
   what the testbench will check.

## Next

`/fpga-testbench` (write it first if not already), then `/fpga-questa`.
