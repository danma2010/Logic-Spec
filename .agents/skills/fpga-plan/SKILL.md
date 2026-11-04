---
name: fpga-plan
description: Produce the design plan for a unit and open gate 1 (plan approval). Use after fpga-architect and before ANY code generation. Writes spec/plan.md (status pending) covering module hierarchy, sub-units, IP configuration, block-design topology, verification strategy and simulation setup, then asks the user to approve.
---

# FPGA Plan — gate 1

## Gate check (do this first)

Require `spec/spec_work.md` with `status: approved` whose `spec_sha256`
matches the current `spec/spec.md` (gate 0). Otherwise stop and run `fpga-spec`.
Require `spec/architecture.md`.

Read `spec/architecture.md` (and `spec/spec_work.md` for context). Produce a
concrete, buildable plan. Write no HDL or Tcl.

## plan.md front-matter (required)

```markdown
---
status: pending
---
```

## plan.md sections

1. **Module hierarchy** — the unit's `top` entity (`rtl/<top>.vhd`) and its
   submodules. List each instantiated sub-unit from `dependencies` (a design
   folder path) with its current status from `<dep>/spec/architecture.md`. **Any sub-unit not `validated` blocks approval** — say so
   and keep the plan `pending`.
2. **IP selection & configuration** — resolve each abstract IP to the chosen
   vendor (FIFO Generator, XPM macro, …); flag any forced-Verilog core.
3. **Block-design topology** (optional) — only for vendor IP wired *inside*
   this unit; the BD wrapper is instantiated by the RTL top. Unit-to-unit
   composition is always direct RTL.
4. **Verification strategy** — cocotb on Questa by default (UVM only if
   flagged); the default testbench configuration (real `top`, real IP models);
   any behavioural stand-ins for a fast loop; for a composite/top, the
   **integration test** at this unit's interface. The detailed test list comes
   later in `fpga-testplan`.
5. **Simulation setup** — compile order (sub-units first), vendor libs from
   `{{LOGIC_SPEC}}/simlibs/questa` (`{{LOGIC_SPEC}}/tools/compile_simlib.tcl`), runner `{{LOGIC_SPEC}}/tools/run_tests.sh`.

## The gate

Present a summary and ask the user to approve. On approval set
`status: approved`. If changes are requested, revise and keep `pending`. Any
later change to the plan's content sets it back to `pending`.
**No generation skill may run until `status: approved`.**

## Next

`fpga-testplan`.

## Design log

Prepend an entry to `spec/design_log.md` (format:
`{{LOGIC_SPEC}}/templates/design_log.md`): same cycle number while the unit is in the same
design round, +1 when a new round starts (e.g. after a validated unit is
changed). Record the stage completed, unit status, plan / test-plan status and
test results.
