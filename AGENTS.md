<!-- GENERATED from CLAUDE.md by tools/sync_agents.sh — do not edit here. -->
# Logic-Spec — FPGA Spec-Driven Design Rules


These rules apply to a **design project** that uses the Logic-Spec framework: a
**spec-driven, gated, hierarchical FPGA design flow** for coding agents (Claude
Code and Antigravity). The agent generates each design (refined spec, vendor IP
config, custom RTL, test plan, testbenches) and the scripts to build/simulate
it. **The user runs Questa and Vivado** by executing the generated scripts; the
agent runs EDA tools only in the opt-in auto mode (rule 7).

## Framework vs. design

- **Framework** — installed once at `{{LOGIC_SPEC}}` (`tools/`, `templates/`,
  `simlibs/`); skills are installed user-wide by `tools/install.sh`. Designs
  never live inside the framework tree (except `examples/`).
- **Design project** — any folder, **one design = one folder = one unit**. It
  references the framework through two pointer files (`CLAUDE.md`,
  `AGENTS.md`) created by `fpga-spec` / `tools/new_design.sh`.
- In skills and commands, `<design>` is the design project's root folder
  (normally the open workspace) and `{{LOGIC_SPEC}}` the framework root.

## Files of a design (the data model)

All documents the framework reads or writes live in `<design>/spec/`; code and
scripts live beside it in `<design>/`.

| File | Role | Written by |
|---|---|---|
| `spec/spec.md` | **Input** requirements from the user. **Never modified** by any skill. | user |
| `spec/spec_work.md` | **Refined spec**: one requirements table, IDs from one shared counter starting at 0: `R-n` stated by the user, `RR-n` derived or assumed (e.g. R-0, R-1, RR-2), plus the clarifications log. `status: pending → approved`. The input of every later step. | `fpga-spec` |
| `spec/architecture.md` | **Unit manifest** (front-matter) + structured architecture: interfaces, abstract IP, numbered acceptance criteria `AC-n`, pin map if top. The **only** place a unit's `status` lives. | `fpga-architect`, `status` by rtl/review/auto |
| `spec/plan.md` | Design plan, `status: pending → approved` | `fpga-plan` |
| `spec/testplan.md` | Test collection `T01…`, `status: pending → approved` | `fpga-testplan` |
| `spec/design_log.md` | Stage log, newest cycle on top | every generating skill |
| `sim/test_report.md` | Per-test PASS/FAIL report | `run_tests.sh` |

Manifest front-matter (`spec/architecture.md`):

```yaml
name: <unit>              # = design folder name
vendor: xilinx            # xilinx | altera
part: <part>              # target device, used by synth check / build
kind: leaf                # leaf | composite | top
top: <entity>             # top entity of this unit, in rtl/<entity>.vhd
status: planned           # planned | generated | validated
dependencies: []          # other design folders, path relative to <design> (e.g. ../axis_fifo)
ports: []                 # - { name, dir, width }
validated: {}             # { date, tests, report } — set only by the validation gate
```

### Unit status lifecycle

- `planned` — `fpga-architect` wrote `architecture.md`; no RTL yet.
- `generated` — `fpga-rtl` wrote RTL (set on first write).
- `validated` — every `must` test passed on current sources (rule 5).
- **Any change** to `rtl/`, `tb/`, IP Tcl or `spec/testplan.md` of a
  `validated` unit sets it back to `generated` and clears `validated: {}` — and
  every unit that depends on it must be re-validated before its next use.
- **Any change** to an approved `spec/spec_work.md` sets it back to `pending`
  (gate 0); once re-approved, `fpga-architect` re-derives `architecture.md` and
  `plan.md` goes back to `pending`.

## Units and hierarchy

- `kind: leaf` — custom RTL + vendor IP only.
- `kind: composite` — also instantiates other **validated** units.
- `kind: top` — the composite designated as the FPGA top; its interface is the
  FPGA's physical pins.

A unit is **reused by direct RTL instantiation** of its `top` entity (from
`<dep>/rtl/<top>.vhd`, `<dep>` = the dependency's design folder); the child's
`rtl/*.vhd` (and its IP) are compiled into the parent. Units are **not**
packaged as IP or block-design containers for reuse. A unit's `top` must
therefore be an RTL entity — a block design may exist *inside* a unit, but the
unit's top is never a BD wrapper.

## The workflow

```
per design:
  fpga-spec        → spec/spec_work.md  (review spec.md, ask, refine)
                     PENDING → user approves → APPROVED                 ← GATE 0: SPEC
  fpga-architect   → spec/architecture.md  (from spec_work.md; vendor, kind, deps, AC-n)
  fpga-plan        → spec/plan.md      PENDING → user approves → APPROVED   ← GATE 1: PLAN
     ── no code until plan.md is APPROVED ──
  fpga-testplan    → spec/testplan.md  PENDING → user approves → APPROVED   ← GATE 2: TEST PLAN
  fpga-ip          → tcl/build_ip.tcl         (user runs in Vivado)
  fpga-blockdesign → bd/build_bd.tcl          (Xilinx, optional, inside the unit)
  fpga-rtl         → rtl/*.vhd                status → generated
  fpga-testbench   → tb/*.py + tb/Makefile    (one cocotb test per testplan entry)
  fpga-questa      → sim scripts              (user runs: bash {{LOGIC_SPEC}}/tools/run_tests.sh <design>)
                     → tests run one by one → sim/test_report.md
  fpga-review      → repair test by test; all MUST tests PASS → validated  ← GATE 3: VALIDATION

at the top:
  fpga-toplevel    → xdc/*.xdc + impl/build.tcl (+ run_sources.tcl, run_constraints.tcl)
                     + top integration test (user runs in Vivado/Questa)

opt-in:
  fpga-auto        → runs run_tests.sh + OOC synth check itself, bounded
```

## HARD RULES

1. **Input is read-only.** Never modify `spec/spec.md`. All refinement lives in
   `spec/spec_work.md`; all derived content and status in `spec/architecture.md`.
2. **Spec gate (gate 0).** No other skill runs until `spec/spec_work.md` exists
   with `status: approved` **and** its recorded `spec.md` hash matches the
   current `spec/spec.md`. Every later step reads `spec_work.md`, never
   `spec.md`, as its requirements. Missing or ambiguous information is asked of
   the user — never silently invented; every assumption is written down and
   approved with `spec_work.md`.
3. **Plan gate.** Never generate RTL, IP, block-design, testbench, or EDA Tcl
   until `spec/plan.md` exists with `status: approved`. Every generation skill
   re-checks this and stops if it isn't met. `fpga-plan` may not approve a plan
   whose dependencies are not all `status: validated`.
4. **Test-plan gate.** Verification is a **collection of tests** planned up
   front. Never generate testbench code until `spec/testplan.md` has
   `status: approved`. Each test has an ID (`T01`…), a cocotb function name, the
   features and acceptance criteria (`AC-n`) it covers, a priority
   (`must`/`should`) and a measurable **pass criterion**; each maps to exactly
   one cocotb test. Every `AC-n` is covered by at least one `must` test. Never
   loosen a pass criterion to get a pass — any edit to `testplan.md` puts it
   back to `pending`.
5. **Validation gate.** A unit may be instantiated in another unit **only** when
   its `spec/architecture.md` says `status: validated`. That is set (by
   `fpga-review`, or by `fpga-auto` after user confirmation) only when
   `sim/test_report.md` shows **every `must` test PASS** on current sources, in
   the **default** testbench configuration (the unit's real `top` with real IP
   models — behavioural stand-ins are for the fast loop only). `should`
   failures need a waiver recorded in `testplan.md`.
6. **Reuse = direct RTL instantiation** of the child's `top` entity; a
   dependency is another design folder, referenced by relative path.
7. **EDA execution is manual by default.** The agent produces scripts and never
   claims to have run them — it prints the exact command and waits for results.
   **Exception: `fpga-auto`**, only when the user explicitly invokes it: the
   agent may run `run_tests.sh` and `run_synth_check.sh` itself, bounded by its
   guardrails. Never implementation, bitstream or hardware.
8. **HDL policy.** VHDL-2008 primary. Verilog/SV only where a vendor IP forces
   it — unless `spec_work.md` explicitly specifies another HDL or simulator.
9. **Vendor.** One target (Xilinx or Altera) per unit, chosen at the
   architecture stage; IP stays abstract until then.
10. **Verification-first.** Test plan from the acceptance criteria, then the
    testbench from the test plan, before/with the RTL. cocotb on Questa by
    default; UVM only if the plan flags it.
11. **Top-level pins.** The pin map lives in the top unit's `architecture.md`
    (or a file it references). `fpga-toplevel` turns it into constraints and a
    non-project build.
12. **Never delete files without explicit user approval.** When editing an
    existing constraints or build script, extend/patch it — do not clobber it.
13. **Paths.** Every generated Tcl script resolves paths relative to its own
    location (`[file dirname [info script]]`), so it works from any directory.
    Framework files are referenced through `{{LOGIC_SPEC}}`; nothing is
    written into the framework tree except the shared `simlibs/`.
14. **Design log.** Every skill that writes files prepends an entry to
    `spec/design_log.md` (format: `{{LOGIC_SPEC}}/templates/design_log.md`).
    Read-only roles (`fpga-critic`) do not.

## Design project layout

```
<design>/                     one design = one unit = one folder (anywhere)
  CLAUDE.md, AGENTS.md        pointers to the framework rules              (fpga-spec)
  spec/
    spec.md                   input requirements (never modified)          (user)
    spec_work.md              refined spec          ← gate 0               (fpga-spec)
    architecture.md           manifest + architecture + AC-n (+ pin map)   (fpga-architect)
    plan.md                   the plan              ← gate 1               (fpga-plan)
    testplan.md               tests, pass criteria  ← gate 2               (fpga-testplan)
    design_log.md             stage log, newest first                      (all writers)
  rtl/                        custom VHDL, rtl/<top>.vhd = unit top        (fpga-rtl)
  tb/                         cocotb tests + Makefile                      (fpga-testbench)
  tcl/                        Vivado IP Tcl; generated IP in tcl/ip/       (fpga-ip)
  bd/                         Xilinx block design Tcl (optional)           (fpga-blockdesign)
  sim/                        RUN.md, run_sim.tcl (UVM path only)          (fpga-questa)
    tests/<ID>.log|.xml       per-test results                             (run_tests.sh)
    test_report.md|.json      pass/fail report                             (make_report.py)
    auto_log.md               auto-mode audit trail                        (fpga-auto)
  build/                      OOC synth check workspace                    (fpga-auto)
  xdc/                        constraints (top only)                       (fpga-toplevel)
  impl/                       build.tcl + run_sources.tcl + run_constraints.tcl (top only)

{{LOGIC_SPEC}}/simlibs/questa/  vendor sim libraries, shared by all designs (tools/compile_simlib.tcl)
```

## Skills

| Skill | Role | Produces |
|---|---|---|
| `fpga-spec` | review spec.md, ask for missing info, refine + gate 0 | `spec/spec_work.md` (+ design scaffold) |
| `fpga-architect` | refined spec → architecture, vendor, manifest, hierarchy | `spec/architecture.md` |
| `fpga-plan` | the plan + gate 1 | `spec/plan.md` |
| `fpga-testplan` | test collection + pass criteria + gate 2 | `spec/testplan.md` |
| `fpga-ip` | resolve/config vendor IP | `tcl/build_ip.tcl` |
| `fpga-blockdesign` | Xilinx BD in Tcl (inside a unit) | `bd/build_bd.tcl` |
| `fpga-rtl` | custom VHDL + sub-unit instantiation | `rtl/*.vhd`, status `generated` |
| `fpga-testbench` | cocotb tests from the test plan, hierarchy-aware | `tb/*.py`, `tb/Makefile` |
| `fpga-questa` | Questa scripts + run instructions | `sim/*` |
| `fpga-review` | read per-test report, repair, gate 3 | fixes, status `validated` |
| `fpga-toplevel` | pins → constraints + non-project build + top sim | `xdc/*`, `impl/*` |
| `fpga-auto` | opt-in: run tests + OOC synth loop, bounded | `sim/test_report.md`, `sim/auto_log.md` |
| `fpga-critic` | isolated sim-log/waveform diagnosis (read-only) | diagnosis only |

Tools (plain scripts in `{{LOGIC_SPEC}}/tools/`, run by the user — or by
`fpga-auto`; `<design>` is a path, e.g. `.`):

- `run_tests.sh <design> [SIM] [ID…]` — lint the test plan, run tests one by
  one, write `<design>/sim/test_report.md`.
- `make_report.py --check|--list|--report <design>` — test-plan lint, test
  list, report builder.
- `run_synth_check.sh <design>` — OOC synthesizability check.
- `run_sim.sh <design> [SIM]` — quick smoke check while iterating: all tests in
  one simulator run, one-line verdict. Never counts for validation.
- `new_design.sh <design>` — create a design folder: `spec/`, pointer files,
  `.gitignore` (never overwrites).
- `install.sh` — install/refresh the skills user-wide and the rules in
  `~/.logic-spec/` (framework maintainers: after every framework edit).
- `sync_agents.sh` — regenerate `AGENTS.md` and `.agents/skills/` from
  `CLAUDE.md` and `.claude/` (run before `install.sh`).

The generate → simulate → repair loop: `{{LOGIC_SPEC}}/docs/LOOP.md`.
Rationale: `{{LOGIC_SPEC}}/docs/framework-design-spec.md`.
