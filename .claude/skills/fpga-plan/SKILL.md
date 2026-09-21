---
name: fpga-plan
description: Produce the design plan for a unit and open the approval gate. Use after fpga-architect and before ANY code generation. Writes designs/<name>/plan.md (status pending) covering module hierarchy (including instantiated validated sub-units), IP configuration, block-design topology, testbench strategy, and simulation setup, then asks the user to approve.
---

# FPGA Plan — the approval gate

Read `designs/<name>/spec.md` and `designs/<name>/unit.md`. Produce a concrete,
buildable plan. Write no HDL or Tcl.

## plan.md front-matter (required)

```markdown
---
status: pending
---
```

## plan.md sections

1. **Module hierarchy** — VHDL top plus submodules. List each instantiated
   **validated** sub-unit (from `unit.md` dependencies) and confirm each is
   `status: validated` — if any is not, stop and say so.
2. **IP selection & configuration** — resolve each abstract IP to the chosen
   vendor; flag any forced-Verilog core.
3. **Block-design topology** — Xilinx IP Integrator BD (for vendor IP within this
   unit); Altera Platform Designer. Unit-to-unit composition is direct RTL, not
   BD.
4. **Testbench strategy** — cocotb on Questa by default; for a composite/top,
   describe the **integration test** at this unit's interface (sub-units keep
   their own standalone validation).
5. **Simulation setup** — compile order (sub-unit RTL first), vendor libs via
   `-L`, cocotb `Makefile` vs `run_sim.tcl`.

## The gate

Present a summary and ask the user to approve. On approval set
`status: approved`. If changes are requested, revise and keep `status: pending`.
**No generation skill may run until `status: approved`.**
