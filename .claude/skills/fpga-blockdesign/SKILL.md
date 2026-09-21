---
name: fpga-blockdesign
description: Assemble the Xilinx block design (IP Integrator) in Tcl, wiring configured vendor IP together with custom RTL per the approved plan. Xilinx targets only. Writes designs/<name>/bd/build_bd.tcl for the user to run manually in Vivado; it never runs Vivado itself.
---

# FPGA Block Design (Xilinx)

## Gate check (do this first)

Require `designs/<name>/plan.md` with `status: approved`. Otherwise stop and ask
for approval. Also confirm the vendor is `xilinx` (Altera uses Platform
Designer, not this skill).

## Steps

1. From the plan's block-design topology, emit `designs/<name>/bd/build_bd.tcl`
   based on `templates/vivado/build_bd.tcl`:
   `create_bd_design` → `create_bd_cell` for each IP and RTL module reference →
   `connect_bd_net` / `connect_bd_intf_net` → `validate_bd_design` →
   `save_bd_design` → `make_wrapper`.
2. Add custom RTL modules to the BD as module references (they must exist under
   `rtl/`, or note that `/fpga-rtl` must run first).
3. **Do not run Vivado.** Print the manual command and wait:

   ```
   vivado -mode batch -source designs/<name>/bd/build_bd.tcl
   ```
