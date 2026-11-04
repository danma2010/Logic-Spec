---
name: fpga-toplevel
description: Assemble and build the top-level unit. From the pin map in architecture.md, generate or patch the FPGA constraints (XDC for Xilinx, QSF+SDC for Altera); generate or patch a Vivado non-project build that sources separate source-list and constraint-list Tcl files; and ensure the top integration test exists. Use once a unit is kind: top and all its sub-units are validated. Never runs Vivado.
---

# FPGA Top-Level

Interface → pins → constraints → non-project build, plus a top integration sim.

## Gate checks (do these first)

1. `spec/architecture.md` has `kind: top`; `spec/plan.md` and
   `spec/testplan.md` are `status: approved`.
2. **Every** unit in `dependencies` (transitively: each `<dep>/spec/architecture.md`
   and its own dependencies) is `status: validated`.
   If any is not, stop and name it.

## Steps

### 1. Constraints from the pin map
Read the pin map from `spec/architecture.md` (or the file it references). Generate
or **patch** `xdc/<top>_pins.xdc` (from `{{LOGIC_SPEC}}/templates/xdc/pins.xdc`):

- Xilinx: `set_property PACKAGE_PIN <pin> [get_ports <port>]`,
  `set_property IOSTANDARD <std> [get_ports <port>]`,
  `create_clock -name <clk> -period <ns> [get_ports <clk_port>]`.
- Altera: `set_location_assignment PIN_<pin> -to <port>` +
  `set_instance_assignment -name IO_STANDARD <std> -to <port>` in the QSF, and
  `create_clock` in the SDC.

If a constraints file exists, patch it — never clobber it.

### 2. Non-project build (modular)
Generate or patch `impl/build.tcl` from
`{{LOGIC_SPEC}}/templates/vivado/build.tcl` (`TOP`/`PART` from `spec/architecture.md`). It sources,
from its own directory:

- `run_sources.tcl` (from `{{LOGIC_SPEC}}/templates/vivado/run_sources.tcl`) — all RTL of the
  hierarchy **bottom-up** (leaf design folders, then composites, then the top;
  dependency paths relative to the script), plus
  `read_ip` for generated IP and `read_bd` for any BD;
- `run_constraints.tcl` — `read_xdc` of the files from step 1.

Keep `build.tcl` stable; file lists live only in the two sourced scripts. All
paths are resolved from the script location. Versal: `write_device_image`
instead of `write_bitstream`.

### 3. Top integration test
The top's tests come from its own `spec/testplan.md` (run `fpga-testbench` for the
top so the full subtree is compiled) and run with `bash {{LOGIC_SPEC}}/tools/run_tests.sh .`.

## Manual run (print; do not run)

```
bash {{LOGIC_SPEC}}/tools/run_tests.sh .                                # integration tests
vivado -mode batch -source impl/build.tcl      # to bitstream
```

## Design log

Prepend an entry to `spec/design_log.md` (format:
`{{LOGIC_SPEC}}/templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
