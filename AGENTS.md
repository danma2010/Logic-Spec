<!-- GENERATED from CLAUDE.md by tools/sync_agents.sh — do not edit here. -->
# FPGA Spec-Driven Design — Project Rules


This repo is a **spec-driven, plan-gated, hierarchical FPGA design framework**
for coding agents (Claude Code via `CLAUDE.md` + `.claude/`, Antigravity via
`AGENTS.md` + `.agents/`). The agent generates each design (vendor IP config,
custom RTL, test plan, testbenches) and the scripts to build/simulate it. **The
user runs Questa and Vivado** by executing the generated scripts; the agent
runs EDA tools only in the opt-in auto mode (rule 6).

## Files of a unit (the data model)

| File | Role | Written by |
|---|---|---|
| `spec.md` | **Input** requirements from the user. **Never modified** by any skill. | user |
| `architecture.md` | **Unit manifest** (front-matter) + structured architecture: interfaces, abstract IP, numbered acceptance criteria `AC-n`, pin map if top. The **only** place a unit's `status` lives. | `fpga-architect`, `status` by rtl/review/auto |
| `plan.md` | Design plan, `status: pending → approved` | `fpga-plan` |
| `testplan.md` | Test collection `T01…`, `status: pending → approved` | `fpga-testplan` |
| `design_log.md` | Stage log, newest cycle on top | every generating skill |
| `sim/test_report.md` | Per-test PASS/FAIL report | `tools/run_tests.sh` |

Manifest front-matter (`architecture.md`):

```yaml
name: <unit>              # = directory name
vendor: xilinx            # xilinx | altera
part: <part>              # target device, used by synth check / build
kind: leaf                # leaf | composite | top
top: <entity>             # top entity of this unit, in rtl/<entity>.vhd
status: planned           # planned | generated | validated
dependencies: []          # sub-unit names (direct RTL instantiation)
ports: []                 # - { name, dir, width }
validated: {}             # { date, tests, report } — set only by the validation gate
```

### Unit status lifecycle

- `planned` — `fpga-architect` wrote `architecture.md`; no RTL yet.
- `generated` — `fpga-rtl` wrote RTL (set on first write).
- `validated` — every `must` test passed on current sources (rule 4).
- **Any change** to `rtl/`, `tb/`, IP Tcl or `testplan.md` of a `validated`
  unit sets it back to `generated` and clears `validated: {}` — and every unit
  that depends on it must be re-validated before its next use.

## Units and hierarchy

- `kind: leaf` — custom RTL + vendor IP only.
- `kind: composite` — also instantiates other **validated** units.
- `kind: top` — the composite designated as the FPGA top; its interface is the
  FPGA's physical pins.

A unit is **reused by direct RTL instantiation** of its `top` entity (from
`rtl/<top>.vhd`); the child's `rtl/*.vhd` (and its IP) are compiled into the
parent. Units are **not** packaged as IP or block-design containers for reuse.
A unit's `top` must therefore be an RTL entity — a block design may exist
*inside* a unit, but the unit's top is never a BD wrapper.

## The workflow

```
per unit:
  fpga-architect   → architecture.md  (from spec.md; vendor, kind, deps, AC-n)
  fpga-plan        → plan.md      PENDING → user approves → APPROVED   ← GATE 1: PLAN
     ── no code until plan.md is APPROVED ──
  fpga-testplan    → testplan.md  PENDING → user approves → APPROVED   ← GATE 2: TEST PLAN
  fpga-ip          → tcl/build_ip.tcl         (user runs in Vivado)
  fpga-blockdesign → bd/build_bd.tcl          (Xilinx, optional, inside the unit)
  fpga-rtl         → rtl/*.vhd                status → generated
  fpga-testbench   → tb/*.py + tb/Makefile    (one cocotb test per testplan entry)
  fpga-questa      → sim scripts              (user runs: bash tools/run_tests.sh <unit>)
                     → tests run one by one → sim/test_report.md
  fpga-review      → repair test by test; all MUST tests PASS → validated  ← GATE 3: VALIDATION

at the top:
  fpga-toplevel    → xdc/*.xdc + impl/build.tcl (+ run_sources.tcl, run_constraints.tcl)
                     + top integration test (user runs in Vivado/Questa)

opt-in:
  fpga-auto        → runs tools/run_tests.sh + OOC synth check itself, bounded
```

## HARD RULES

1. **Input is read-only.** Never modify `designs/<name>/spec.md`. All derived
   content and all status live in `architecture.md`.
2. **Plan gate.** Never generate RTL, IP, block-design, testbench, or EDA Tcl
   until `plan.md` exists with `status: approved`. Every generation skill
   re-checks this and stops if it isn't met. `fpga-plan` may not approve a plan
   whose dependencies are not all `status: validated`.
3. **Test-plan gate.** Verification is a **collection of tests** planned up
   front. Never generate testbench code until `testplan.md` has
   `status: approved`. Each test has an ID (`T01`…), a cocotb function name, the
   features and acceptance criteria (`AC-n`) it covers, a priority
   (`must`/`should`) and a measurable **pass criterion**; each maps to exactly
   one cocotb test. Every `AC-n` is covered by at least one `must` test. Never
   loosen a pass criterion to get a pass — any edit to `testplan.md` puts it
   back to `pending`.
4. **Validation gate.** A unit may be instantiated in another unit **only** when
   its `architecture.md` says `status: validated`. That is set (by
   `fpga-review`, or by `fpga-auto` after user confirmation) only when
   `sim/test_report.md` shows **every `must` test PASS** on current sources, in
   the **default** testbench configuration (the unit's real `top` with real IP
   models — behavioural stand-ins are for the fast loop only). `should`
   failures need a waiver recorded in `testplan.md`.
5. **Reuse = direct RTL instantiation** of the child's `top` entity.
6. **EDA execution is manual by default.** The agent produces scripts and never
   claims to have run them — it prints the exact command and waits for results.
   **Exception: `fpga-auto`**, only when the user explicitly invokes it: the
   agent may run `tools/run_tests.sh` and `tools/run_synth_check.sh` itself,
   bounded by its guardrails. Never implementation, bitstream or hardware.
7. **HDL policy.** VHDL-2008 primary. Verilog/SV only where a vendor IP forces it.
8. **Vendor.** One target (Xilinx or Altera) per unit, chosen at the
   architecture stage; IP stays abstract until then.
9. **Verification-first.** Test plan from the acceptance criteria, then the
   testbench from the test plan, before/with the RTL. cocotb on Questa by
   default; UVM only if the plan flags it.
10. **Top-level pins.** The pin map lives in the top unit's `architecture.md`
    (or a file it references). `fpga-toplevel` turns it into constraints and a
    non-project build.
11. **Never delete files without explicit user approval.** When editing an
    existing constraints or build script, extend/patch it — do not clobber it.
12. **Paths.** Every generated Tcl script resolves paths relative to its own
    location (`[file dirname [info script]]`), so it works from any directory.
13. **Design log.** Every skill that writes files prepends an entry to
    `design_log.md` (format: `templates/design_log.md`). Read-only roles
    (`fpga-critic`) do not.

## Design directory layout

```
designs/<name>/
  spec.md            input requirements (never modified)          (user)
  architecture.md    manifest + architecture + AC-n (+ pin map)   (fpga-architect)
  plan.md            the plan                ← gate 1             (fpga-plan)
  testplan.md        tests, pass criteria    ← gate 2             (fpga-testplan)
  design_log.md      stage log, newest first                      (all writers)
  rtl/               custom VHDL, rtl/<top>.vhd = unit top        (fpga-rtl)
  tb/                cocotb tests + Makefile                      (fpga-testbench)
  tcl/               Vivado IP Tcl; generated IP in tcl/ip/       (fpga-ip)
  bd/                Xilinx block design Tcl (optional)           (fpga-blockdesign)
  sim/               RUN.md, run_sim.tcl (UVM path only)          (fpga-questa)
    tests/<ID>.log|.xml   per-test results                        (tools/run_tests.sh)
    test_report.md|.json  pass/fail report                        (tools/make_report.py)
    auto_log.md           auto-mode audit trail                   (fpga-auto)
  build/             OOC synth check workspace                    (fpga-auto)
  xdc/               constraints (top only)                       (fpga-toplevel)
  impl/              build.tcl + run_sources.tcl + run_constraints.tcl (top only)
simlibs/questa/      vendor sim libraries, shared by all units    (tools/compile_simlib.tcl)
```

## Skills

| Skill | Role | Produces |
|---|---|---|
| `fpga-architect` | requirements → architecture, vendor, manifest, hierarchy | `architecture.md` |
| `fpga-plan` | the plan + gate 1 | `plan.md` |
| `fpga-testplan` | test collection + pass criteria + gate 2 | `testplan.md` |
| `fpga-ip` | resolve/config vendor IP | `tcl/build_ip.tcl` |
| `fpga-blockdesign` | Xilinx BD in Tcl (inside a unit) | `bd/build_bd.tcl` |
| `fpga-rtl` | custom VHDL + sub-unit instantiation | `rtl/*.vhd`, status `generated` |
| `fpga-testbench` | cocotb tests from the test plan, hierarchy-aware | `tb/*.py`, `tb/Makefile` |
| `fpga-questa` | Questa scripts + run instructions | `sim/*` |
| `fpga-review` | read per-test report, repair, gate 3 | fixes, status `validated` |
| `fpga-toplevel` | pins → constraints + non-project build + top sim | `xdc/*`, `impl/*` |
| `fpga-auto` | opt-in: run tests + OOC synth loop, bounded | `sim/test_report.md`, `sim/auto_log.md` |
| `fpga-critic` | isolated sim-log/waveform diagnosis (read-only) | diagnosis only |

Tools (plain scripts, run by the user — or by `fpga-auto`):

- `tools/run_tests.sh <unit> [SIM] [ID…]` — lint the test plan, run tests one
  by one, write `sim/test_report.md`.
- `tools/make_report.py --check|--list|--report designs/<unit>` — test-plan
  lint, test list, report builder.
- `tools/run_synth_check.sh <unit>` — OOC synthesizability check.
- `tools/run_sim.sh <unit> [SIM]` — quick smoke check while iterating: all tests in
  one simulator run, one-line verdict. Never counts for validation (see README,
  "Two test runners").
- `tools/sync_agents.sh` — regenerate `AGENTS.md` and `.agents/skills/` from
  `CLAUDE.md` and `.claude/skills/`.

The generate → simulate → repair loop: `docs/LOOP.md`.
Rationale: `docs/framework-design-spec.md`.
