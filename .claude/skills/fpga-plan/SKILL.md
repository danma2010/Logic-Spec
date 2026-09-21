---
name: fpga-plan
description: Produce the design plan for an FPGA design and open the approval gate. Use after fpga-architect and before ANY code generation. Writes designs/<name>/plan.md (status pending) covering module hierarchy, IP configuration, block-design topology, testbench strategy, and Questa simulation setup, then asks the user to approve.
---

# FPGA Plan — the approval gate

Read `designs/<name>/spec.md` and produce a concrete, buildable plan. **Write no
HDL or Tcl** — this is the plan a human approves before code generation begins.

## plan.md front-matter (required)

Begin the file with:

```markdown
---
status: pending
---
```

## plan.md sections

1. **Module hierarchy** — top entity is VHDL; list submodules.
2. **IP selection & configuration** — resolve each abstract IP to the chosen
   vendor, with key config parameters. Flag any core that forces Verilog/SV.
3. **Block-design topology** — Xilinx: the IP Integrator BD to assemble in Tcl
   (cells + connections). Altera: the Platform Designer/Qsys system.
4. **Testbench strategy** — cocotb on Questa by default; note UVM only if truly
   required. List the acceptance criteria each test covers.
5. **Simulation setup** — compile order, vendor sim libraries referenced via
   `-L`, and whether the run uses the cocotb `Makefile` or `run_sim.tcl`.

## The gate

After writing `plan.md`, present a short summary and ask the user to approve.

- On approval: set the front-matter to `status: approved`.
- If changes are requested: revise and keep `status: pending`.

**No generation skill may run until `status: approved`.**
