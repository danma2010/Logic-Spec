---
name: fpga-blockdesign
description: Assemble an optional Xilinx block design (IP Integrator) in Tcl inside a unit, wiring configured vendor IP with custom RTL per the approved plan. The BD wrapper is instantiated by the unit's RTL top, never used as the unit top. Xilinx only. Writes designs/<name>/bd/build_bd.tcl for the user to run.
---

# FPGA Block Design (Xilinx, inside a unit)

## Gate check (do this first)

Require `designs/<name>/plan.md` with `status: approved` and a block-design
section in the plan. Confirm `vendor: xilinx` (Altera uses Platform Designer).

## Steps

1. Emit `designs/<name>/bd/build_bd.tcl` from `templates/vivado/build_bd.tcl`:
   `create_project -in_memory -part <part>` → `read_vhdl` the RTL used as
   module references → `create_bd_design -dir $SCRIPT_DIR` → `create_bd_cell`
   → `connect_bd_net` / `connect_bd_intf_net` (connect **every** input,
   including IP resets) → `validate_bd_design` → `save_bd_design` →
   `make_wrapper` → `generate_target`.
2. Module-reference RTL must already exist under `rtl/` (else run `fpga-rtl`
   first) and must not be VHDL-2008-only.
3. The unit's RTL top (`rtl/<top>.vhd`) instantiates `<name>_bd_wrapper`;
   tell `fpga-rtl` and record the BD in `run_sources`/`synth_sources`.
4. **Do not run Vivado.** Print the command and wait:

   ```
   vivado -mode batch -source designs/<name>/bd/build_bd.tcl
   ```

## Design log

Prepend an entry to `designs/<name>/design_log.md` (format:
`templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
