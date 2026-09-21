---
name: fpga-toplevel
description: Assemble and build the top-level unit. From the top spec's pin map, generate or edit the FPGA constraints (XDC for Xilinx, QSF+SDC for Altera); generate or edit a Vivado non-project build script that sources separate source-list and constraint-list Tcl files; and ensure a top-level integration testbench and simulation script exist. Use once a unit is designated kind: top and all its sub-units are validated. Never runs Vivado.
---

# FPGA Top-Level

Turns the designated top unit into a buildable FPGA: interface → pins →
constraints → non-project build, plus a top integration sim.

## Gate checks (do these first)

1. `designs/<top>/unit.md` has `kind: top` and `plan.md` is `status: approved`.
2. **Every** unit in `dependencies` (transitively) is `status: validated`.
   If any is not, stop and name it.

## Steps

### 1. Constraints from the pin map
Read the pin map from `designs/<top>/spec.md` (or the file it references): each
`top port → package pin → IO standard`, plus clocks. Generate or **edit**
`designs/<top>/xdc/<top>_pins.xdc` (based on `templates/xdc/pins.xdc`):

- Xilinx: `set_property PACKAGE_PIN <pin> [get_ports <port>]`,
  `set_property IOSTANDARD <std> [get_ports <port>]`,
  `create_clock -name <clk> -period <ns> [get_ports <clk_port>]`.
- Altera: `set_location_assignment PIN_<pin> -to <port>` +
  `set_instance_assignment -name IO_STANDARD <std> -to <port>` in the QSF, and
  `create_clock` in the SDC.

If a constraints file already exists, **patch it** (add/adjust the mapped ports),
do not clobber it.

### 2. Non-project build script (modular)
Generate or edit `designs/<top>/impl/build.tcl` from `templates/vivado/build.tcl`.
It must `source` two separate sub-scripts (edit them if they already exist):

- `run_sources.tcl` — all RTL of the hierarchy read **bottom-up** (leaf sub-units
  first, then composites, then the top), plus `read_ip`/`generate_target` for
  vendor IP.
- `run_constraints.tcl` — `read_xdc` of the constraint files from step 1.

Keep `build.tcl` stable (set_part, source the two files, synth → opt → place →
route → reports → output); put the file lists only in the two sourced scripts.
For Versal parts, replace `write_bitstream` with `write_device_image`.

### 3. Top integration testbench + sim
Ensure a top-level integration test exists (run `/fpga-testbench` for the top so
the full RTL subtree is compiled) and its Questa run script (`/fpga-questa`).

## Manual run (print; do not run)

```
# functional integration sim
cd designs/<top>/tb && make
# implementation to bitstream
vivado -mode batch -source designs/<top>/impl/build.tcl
```
