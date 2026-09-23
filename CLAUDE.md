# FPGA Spec-Driven Design — Project Rules

This repo is a **spec-driven, plan-gated, hierarchical FPGA design framework** for
Claude Code. Claude generates each design (vendor IP config, custom RTL,
testbenches) and the scripts to build/simulate it. **The user runs Questa and
Vivado manually** by executing the generated scripts. Claude never runs EDA tools.

## Units and hierarchy

Every design is a **unit** with a manifest `designs/<name>/unit.md`. A unit is:

- `kind: leaf` — custom RTL + vendor IP only.
- `kind: composite` — also instantiates other **validated** units.
- `kind: top` — the composite designated as the FPGA top; its interface is the
  FPGA's physical pins.

A unit is **reused by direct RTL instantiation** (the child entity is instantiated
in the parent and the child's sources are compiled into the parent). Units are
**not** packaged as IP or block-design containers for reuse. (Vendor IP is still
integrated within a unit via the block design; that is separate from unit reuse.)

Bottom-up: build and validate leaf units, compose them into higher units, and
finally designate one unit `top` and map its interface to pins.

## The workflow

```
per unit:
  /fpga-architect  → spec.md + unit.md      (requirements, vendor, kind, deps)
  /fpga-plan       → plan.md   PENDING → user approves → APPROVED     ← PLAN GATE
     ── no code until plan.md is APPROVED ──
  /fpga-ip         → tcl/build_ip.tcl        (user runs in Vivado)
  /fpga-blockdesign→ bd/build_bd.tcl         (Xilinx, user runs in Vivado)
  /fpga-rtl        → rtl/*.vhd               (instantiates validated sub-units)
  /fpga-testbench  → tb/*.py + tb/Makefile   (cocotb, verification-first)
  /fpga-questa     → sim scripts             (user runs in Questa)
  /fpga-review     → on PASS: unit.md status → VALIDATED               ← VALIDATION GATE

at the top:
  /fpga-toplevel   → xdc/*.xdc + impl/build.tcl (+ run_sources.tcl, run_constraints.tcl)
                     + top integration tb & sim   (user runs in Vivado/Questa)
```

## HARD RULES

1. **Plan gate.** Never generate RTL, IP, block-design, testbench, or EDA Tcl
   until `designs/<name>/plan.md` exists **and** `status: approved`. Every
   generation skill re-checks this and stops if it isn't met.
2. **Validation gate.** A unit may be instantiated in another unit **only** when
   its `unit.md` says `status: validated`. `fpga-review` sets that on a passing
   sim. Never instantiate a `planned` or `generated` unit.
3. **Reuse = direct RTL instantiation.** Instantiate the child entity/component in
   the parent; include the child's RTL sources in the parent's compile/sim.
4. **EDA execution is manual by default.** Claude produces scripts (Vivado Tcl,
   Questa Makefile/Tcl) but never claims to run them — print the exact command and
   wait for pasted results. **Exception: auto mode.** Only when the user
   explicitly invokes `/fpga-auto`, Claude Code may execute the prepared
   *functional-sim* and *OOC synth-check* scripts itself via Bash, bounded by the
   `fpga-auto` guardrails (iteration cap, logging, stop-and-hand-back). Even then
   it reports only real results, never runs implementation/bitstream/hardware, and
   never stamps `validated` without user confirmation.
5. **HDL policy.** VHDL-primary. Verilog/SV only where a vendor IP forces it.
6. **Vendor.** One target (Xilinx or Altera) per unit, chosen at the architecture
   stage; keep IP abstract until then.
7. **Verification-first.** Testbench from acceptance criteria before/with the RTL.
   cocotb on Questa by default; UVM only if the plan flags it.
8. **Top-level pins.** The pin map lives in the top unit's `spec.md` (or a file it
   references). `fpga-toplevel` turns it into constraints and a non-project build.
9. **Never delete files without explicit user approval.** When editing an existing
   constraints or build script, extend/patch it — do not clobber it.

## Design directory layout

```
designs/<name>/
  unit.md      manifest: kind, status, deps, interface   (fpga-architect / fpga-review)
  spec.md      requirements + vendor (+ pin map if top)   (fpga-architect)
  plan.md      the approved plan                           (fpga-plan)   ← plan gate
  rtl/         custom VHDL                                 (fpga-rtl)
  tb/          cocotb tests + Makefile                     (fpga-testbench)
  tcl/         Vivado IP generation Tcl                    (fpga-ip)
  bd/          Xilinx block design Tcl                     (fpga-blockdesign)
  sim/         run scripts, results.xml, logs             (fpga-questa)
  xdc/         constraints (top only)                      (fpga-toplevel)
  impl/        build.tcl + run_sources.tcl + run_constraints.tcl (top only)
```

## Skills

| Skill | Role | Produces |
|---|---|---|
| `/fpga-architect` | requirements, vendor, unit manifest, hierarchy | `spec.md`, `unit.md` |
| `/fpga-plan` | the plan + approval gate | `plan.md` |
| `/fpga-ip` | resolve/config vendor IP | `tcl/build_ip.tcl` |
| `/fpga-blockdesign` | Xilinx BD in Tcl | `bd/build_bd.tcl` |
| `/fpga-rtl` | custom VHDL + sub-unit instantiation | `rtl/*.vhd` |
| `/fpga-testbench` | cocotb testbench (first), hierarchy-aware | `tb/*.py`, `tb/Makefile` |
| `/fpga-questa` | Questa run scripts | `sim/*` |
| `/fpga-review` | read results, repair, stamp VALIDATED | fixes, `unit.md` status |
| `/fpga-toplevel` | pins → constraints + non-project build + top sim | `xdc/*`, `impl/*` |
| `/fpga-auto` | opt-in: run sim + OOC synth loop via Bash, bounded | runs tools, `sim/auto_log.md` |

Subagent `fpga-critic` handles isolated sim-log/waveform analysis.
The generate → simulate → repair loop and its manual boundary: `docs/LOOP.md`.
Full rationale: `docs/framework-design-spec.md`.
