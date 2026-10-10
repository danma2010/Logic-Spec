# FPGA Spec-Driven Design — Project Rules

This repo is a **spec-driven, plan-gated, hierarchical FPGA design framework** for
Claude Code. Claude generates each design (vendor IP config, custom RTL,
testbenches) and the scripts to build/simulate it. **The user runs Questa and
Vivado manually** by executing the generated scripts. Claude never runs EDA tools.

## Units and hierarchy

Every design is a **unit** with a manifest `designs/<name>/spec.md`. A unit is:

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
  /fpga-architect  → spec.md      (requirements, vendor, kind, deps)
  /fpga-plan       → plan.md   PENDING → user approves → APPROVED     ← PLAN GATE
     ── no code until plan.md is APPROVED ──
  /fpga-testplan   → testplan.md PENDING → user approves → APPROVED   ← TEST-PLAN GATE
                     (features, tests T01…, pass criterion each, AC → test trace)
  /fpga-ip         → tcl/build_ip.tcl        (user runs in Vivado)
  /fpga-blockdesign→ bd/build_bd.tcl         (Xilinx, user runs in Vivado)
  /fpga-rtl        → rtl/*.vhd               (instantiates validated sub-units)
  /fpga-testbench  → tb/*.py + tb/Makefile   (one cocotb test per test-plan entry)
  /fpga-questa     → sim scripts             (user runs: bash tools/run_tests.sh <unit>)
                     → tests run one by one → sim/test_report.md (pass/fail per test)
  /fpga-review     → all MUST tests PASS: unit.md status → VALIDATED   ← VALIDATION GATE

at the top:
  /fpga-toplevel   → xdc/*.xdc + impl/build.tcl (+ run_sources.tcl, run_constraints.tcl)
                     + top integration tb & sim   (user runs in Vivado/Questa)
```

## HARD RULES

1. **Plan gate.** Never generate RTL, IP, block-design, testbench, or EDA Tcl
   until `designs/<name>/plan.md` exists **and** `status: approved`. Every
   generation skill re-checks this and stops if it isn't met.
2. **Test-plan gate.** Verification is a **collection of tests** planned up
   front. Never generate testbench code until `designs/<name>/testplan.md` exists
   **and** `status: approved`. Each test has an ID (`T01`…), the features and
   acceptance criteria (`AC-n`) it covers, a priority (`must`/`should`), and a
   measurable **pass criterion**; each maps to exactly one cocotb test of the same
   name. Tests run one by one (`tools/run_tests.sh`) and the result is the
   per-test report `sim/test_report.md`. Never loosen a pass criterion to get a
   pass — changing the test plan puts it back to `pending` for approval.
3. **Validation gate.** A unit may be instantiated in another unit **only** when
   its `unit.md` says `status: validated`. `fpga-review` (or `fpga-auto` after
   user confirmation) sets that only when **every `must` test in the approved
   test plan passes** on current sources (`should` failures need a recorded user
   waiver). Never instantiate a `planned` or `generated` unit.
4. **Reuse = direct RTL instantiation.** Instantiate the child entity/component in
   the parent; include the child's RTL sources in the parent's compile/sim.
5. **EDA execution is manual by default.** Claude produces scripts (Vivado Tcl,
   Questa Makefile/Tcl) but never claims to run them — print the exact command and
   wait for pasted results. **Exception: auto mode.** Only when the user
   explicitly invokes `/fpga-auto`, Claude Code may execute the prepared
   *functional-sim* (test by test, `tools/run_tests.sh`) and *OOC synth-check*
   scripts itself via Bash, bounded by the
   `fpga-auto` guardrails (iteration cap, logging, stop-and-hand-back). Even then
   it reports only real results, never runs implementation/bitstream/hardware, and
   never stamps `validated` without user confirmation.
6. **HDL policy.** VHDL-primary. Verilog/SV only where a vendor IP forces it.
7. **Vendor.** One target (Xilinx or Altera) per unit, chosen at the architecture
   stage; keep IP abstract until then.
8. **Verification-first.** Test plan from the acceptance criteria, then the
   testbench from the test plan, before/with the RTL. cocotb on Questa by
   default; UVM only if the plan flags it.
9. **Top-level pins.** The pin map lives in the top unit's `spec.md` (or a file it
   references). `fpga-toplevel` turns it into constraints and a non-project build.
10. **Never delete files without explicit user approval.** When editing an existing
    constraints or build script, extend/patch it — do not clobber it.

## Design directory layout

```
designs/<name>/
  spec.md      manifest: kind, status, deps, interface   (fpga-architect / fpga-review), 
               requirements + vendor (+ pin map if top)   (fpga-architect)
  design_log.md  status and stage tracking log (prepended per cycle)
  plan.md      the approved plan                           (fpga-plan)   ← plan gate
  testplan.md  tests, pass criteria, AC trace              (fpga-testplan) ← test-plan gate
  rtl/         custom VHDL                                 (fpga-rtl)
  tb/          cocotb tests (1 per test-plan entry) + Makefile (fpga-testbench)
  tcl/         Vivado IP generation Tcl                    (fpga-ip)
  bd/          Xilinx block design Tcl                     (fpga-blockdesign)
  sim/         run scripts, logs                           (fpga-questa)
    tests/<ID>.log|.xml                per-test results     (tools/run_tests.sh)
    test_report.md|.json               pass/fail report     (tools/make_report.py)
  xdc/         constraints (top only)                      (fpga-toplevel)
  impl/        build.tcl + run_sources.tcl + run_constraints.tcl (top only)
```

## Skills

| Skill | Role | Produces |
|---|---|---|
| `/fpga-architect` | requirements, vendor, unit manifest, hierarchy | `spec.md`, `unit.md` |
| `/fpga-plan` | the plan + approval gate | `plan.md` |
| `/fpga-testplan` | test collection + pass criteria + test-plan gate | `testplan.md` |
| `/fpga-ip` | resolve/config vendor IP | `tcl/build_ip.tcl` |
| `/fpga-blockdesign` | Xilinx BD in Tcl | `bd/build_bd.tcl` |
| `/fpga-rtl` | custom VHDL + sub-unit instantiation | `rtl/*.vhd` |
| `/fpga-testbench` | cocotb tests from the test plan, hierarchy-aware | `tb/*.py`, `tb/Makefile` |
| `/fpga-questa` | Questa run scripts | `sim/*` |
| `/fpga-review` | read per-test report, repair test by test, stamp VALIDATED | fixes, `unit.md` status |
| `/fpga-toplevel` | pins → constraints + non-project build + top sim | `xdc/*`, `impl/*` |
| `/fpga-auto` | opt-in: run tests + OOC synth loop via Bash, bounded | runs tools, `sim/test_report.md`, `sim/auto_log.md` |

Tools (plain scripts, run by the user — or by `/fpga-auto`):
`tools/run_tests.sh <unit> [SIM] [ID…]` runs the test plan test by test and
writes the report; `tools/make_report.py` parses/lints `testplan.md`
(`--check`) and builds the report from xUnit results.

Subagent `fpga-critic` handles isolated sim-log/waveform analysis.
The generate → simulate → repair loop and its manual boundary: `docs/LOOP.md`.
Full rationale: `docs/framework-design-spec.md`.
