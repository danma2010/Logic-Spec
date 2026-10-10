---
name: fpga-ip
description: Resolve abstract IP requirements to concrete vendor IP and generate the Vivado (Xilinx) or Platform Designer (Altera) Tcl that configures and instantiates them. Use during generation, only after the plan is approved. Writes designs/<name>/tcl/build_ip.tcl for the user to run manually — it never runs Vivado itself.
---

# FPGA IP-Core

## Gate check (do this first)

Open `designs/<name>/plan.md`. If it does not exist or the front-matter is not
`status: approved`, **stop** and tell the user to approve the plan first. Do not
write any files.

## Steps

1. From `plan.md`, resolve each abstract IP to the concrete vendor part
   (Xilinx `create_ip` module, or Altera `.ip`/`.qsys`).
2. Emit `designs/<name>/tcl/build_ip.tcl`, based on
   `templates/vivado/build_ip.tcl`: `create_ip` → `set_property CONFIG.* …` →
   `generate_target all`. For Altera, emit the `qsys-generate`/`ip-generate`
   equivalent.
3. **Do not run Vivado.** Print the exact manual command and wait:

   ```
   vivado -mode batch -source designs/<name>/tcl/build_ip.tcl
   ```

## Next

`/fpga-blockdesign` (Xilinx) to wire the IP in, then `/fpga-rtl`.


## Status Tracking (design_log.md)

At the end of your execution, you must update `designs/<name>/design_log.md`. Prepend the new status data to the TOP of the file. Include the current cycle version number (determine the current cycle from the existing file and increment if starting a new design round/iteration), the stage you just completed, the overall design status, and the status of the test plan.
