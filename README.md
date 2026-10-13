# Logic-Spec

**A spec-driven, gated, hierarchical FPGA design framework for coding agents.**
The agent turns your requirements into an architecture, a plan, a test plan,
VHDL, vendor-IP Tcl and cocotb testbenches, plus the scripts to build and
simulate them. **You run Questa and Vivado** (or opt in to `fpga-auto`, which
may run simulation and an OOC synth check for you).

Works with **Claude Code** (`CLAUDE.md` + `.claude/`) and **Antigravity**
(`AGENTS.md` + `.agents/`). `CLAUDE.md` and `.claude/` are the source of truth;
`bash tools/sync_agents.sh` regenerates the Antigravity copy.

---

## Mental model

- **Rules** — `CLAUDE.md` / `AGENTS.md`: the data model, the three gates, the
  status lifecycle, HDL/vendor policy, manual-EDA rule.
- **Skills** — `.claude/skills/` (mirrored to `.agents/skills/`): one per
  workflow role (`fpga-architect`, `fpga-plan`, …). Invoke as `/fpga-plan` in
  Claude Code, or by name in Antigravity.
- **Critic** — `fpga-critic`: isolated, read-only failure analysis (a subagent
  in Claude Code, a skill in Antigravity).
- **Tools** — `tools/`: the test runner, report builder, synth check,
  simulation-library compile and the platform sync.
- **Templates** — `templates/`: starting points the skills fill in.

Rationale: `docs/framework-design-spec.md`. The verify loop: `docs/LOOP.md`.

---

## Install

1. Clone/copy this repository as your project root.
2. Open it in Claude Code (`CLAUDE.md` loads automatically; type `/` to see
   the `fpga-*` skills) or in Antigravity (`AGENTS.md`, `.agents/`).
3. Local tooling (the agent never needs it unless you use `fpga-auto`):
   Vivado, Questa, Python 3 with cocotb (`pip install cocotb`).
4. Once per Vivado/Questa version, compile the vendor simulation libraries:
   ```
   QUESTA_BIN=<questa>/bin vivado -mode batch -source tools/compile_simlib.tcl
   ```

---

## Units, files and status

Every design is a **unit** in `designs/<name>/`:

| File | Role |
|---|---|
| `spec.md` | **your input** requirements — never modified by the framework |
| `architecture.md` | the **manifest** (`name, vendor, part, kind, top, status, dependencies, ports, validated`) + architecture + numbered acceptance criteria `AC-n` (+ pin map for the top) |
| `plan.md` | design plan — gate 1 |
| `testplan.md` | tests `T01…` with pass criteria — gate 2 |
| `design_log.md` | stage log, newest first |
| `sim/test_report.md` | per-test PASS/FAIL report — evidence for gate 3 |

`kind`: `leaf` (RTL + vendor IP) · `composite` (instantiates validated units) ·
`top` (the FPGA top, interface = pins). Units are reused by **direct RTL
instantiation** of the child's `top` entity — never as IP or BD containers.

`status`: `planned` (architecture written) → `generated` (RTL written) →
`validated` (gate 3). Changing a validated unit drops it back to `generated`.

## The three gates

1. **Plan** — no RTL/IP/BD/testbench/Tcl before `plan.md` is `approved`, and a
   plan can't be approved while any dependency is not `validated`.
2. **Test plan** — no testbench code before `testplan.md` is `approved`. Every
   `AC-n` is covered by at least one `must` test with a measurable pass
   criterion. Editing the test plan resets it to `pending`.
3. **Validation** — `status: validated` only when `sim/test_report.md` shows
   every `must` test PASS on current sources in the default testbench
   configuration (real top, real IP models), with `should` failures waived.

---

## Workflow

```
per unit
  fpga-architect   spec.md → architecture.md
  fpga-plan        → plan.md       PENDING → you approve → APPROVED     ← gate 1
  fpga-testplan    → testplan.md   PENDING → you approve → APPROVED     ← gate 2
  fpga-ip          → tcl/build_ip.tcl         (you run in Vivado)
  fpga-blockdesign → bd/build_bd.tcl          (optional, Xilinx, inside the unit)
  fpga-rtl         → rtl/*.vhd                status → generated
  fpga-testbench   → tb/*.py + tb/Makefile    one cocotb test per test-plan row
  fpga-questa      → sim/RUN.md (+ run_sim.tcl for UVM)
     ── you run:  bash tools/run_tests.sh <name>   → sim/test_report.md ──
  fpga-review      → repair failing tests; all must PASS → validated     ← gate 3

at the top
  fpga-toplevel    → xdc/<top>_pins.xdc + impl/build.tcl (+ run_sources.tcl, run_constraints.tcl)
     ── you run:  vivado -mode batch -source designs/<top>/impl/build.tcl ──

opt-in
  fpga-auto        → runs run_tests.sh + run_synth_check.sh itself (bounded), asks before validating
```

### Step by step

1. **Input.** Write `designs/<name>/spec.md` (template: `templates/spec.md`) —
   or describe the unit in chat and `fpga-architect` saves your words there.
2. **Architect.** `fpga-architect` → `architecture.md`: vendor, part, kind,
   top entity, dependencies, abstract IP, `AC-n`.
3. **Plan (gate 1).** `fpga-plan` → `plan.md` (`pending`). Review; approve.
4. **Test plan (gate 2).** `fpga-testplan` → `testplan.md`: features, tests
   `T01…`, priority, pass criterion, AC trace. Lint with
   `python3 tools/make_report.py --check designs/<name>`; approve.
5. **IP / BD.** `fpga-ip` (and `fpga-blockdesign` if the plan needs a BD).
   Run the printed `vivado -mode batch -source …` commands.
6. **RTL + testbench.** `fpga-rtl` (unit top in `rtl/<top>.vhd`) and
   `fpga-testbench` (one cocotb test per test-plan row).
7. **Simulate.** `fpga-questa` prints the commands; you run
   `bash tools/run_tests.sh <name>`. Each test runs in its own simulator
   invocation, in plan order; the result is `sim/test_report.md` with seeds,
   logs, AC coverage and a verdict.
8. **Review (gate 3).** `fpga-review` reads the report, fixes failing tests
   one by one (with `fpga-critic` for deep logs) and, when the verdict is
   PASS, stamps `validated`.
9. **Compose.** A higher unit lists the validated unit in `dependencies`;
   `fpga-rtl` instantiates its `top` entity. Repeat 1–8 for the composite (its
   tests are integration tests over the whole subtree).
10. **Top level.** Mark the highest unit `kind: top` with a pin map; run
    `fpga-toplevel`, then the printed Vivado build.

---

## Two test runners — which one to use

| | `tools/run_tests.sh` — **the standard runner** | `tools/run_sim.sh` — **quick smoke check** |
|---|---|---|
| Purpose | Verify a unit against its approved test plan | Fast "does it compile and pass?" feedback while iterating |
| How it runs | One simulator invocation **per test**, in plan order | **One** simulator invocation for all tests (`make` in `tb/`) |
| Test-plan gate | Lints `testplan.md` and refuses to run unless it is `approved` | Not checked — runs whatever cocotb tests exist in `tb/` |
| Output | `sim/test_report.md` + `.json`: per-test result, seed, log, AC coverage, STALE detection, gate-3 verdict | One line (`SIM PASS: 4 tests, 0 failing`) + `sim/last_sim.log` |
| Exit code | 0 gate met · 1 not met · 2 setup error | 0 pass · 1 fail · 2 setup error |
| Counts for validation (gate 3) | **Yes** — full run, default configuration | **Never** |
| Used by | you, `fpga-review`, `fpga-auto` | you only |

**Use `run_sim.sh` when** you are mid-fix and want the quickest possible
feedback (one compile, one run), or for a quick try on another cocotb simulator
before Questa is set up (`bash tools/run_sim.sh <unit> ghdl`).

**Use `run_tests.sh` for everything else** — and always before asking
`fpga-review` to validate a unit. A green `run_sim.sh` is not evidence for
gate 3; only `sim/test_report.md` from `run_tests.sh` is.

---

## Directory layout

```
designs/<name>/
  spec.md  architecture.md  plan.md  testplan.md  design_log.md
  rtl/       custom VHDL; rtl/<top>.vhd is the unit top       (fpga-rtl)
  tb/        cocotb tests + Makefile                           (fpga-testbench)
  tcl/       build_ip.tcl; generated IP in tcl/ip/             (fpga-ip)
  bd/        build_bd.tcl (optional)                           (fpga-blockdesign)
  sim/       RUN.md, run_sim.tcl (UVM)                         (fpga-questa)
    tests/<ID>.log|.xml      per-test results                  (run_tests.sh)
    test_report.md|.json     pass/fail report                  (make_report.py)
    auto_log.md              auto-mode audit trail             (fpga-auto)
  build/     OOC synth-check workspace                         (fpga-auto)
  xdc/ impl/ constraints + non-project build (top only)        (fpga-toplevel)
simlibs/questa/   vendor sim libraries, shared                 (tools/compile_simlib.tcl)
```

Every generated Tcl script resolves paths from its own location, so all
commands work from the repo root (or anywhere).

---

## Command cheat-sheet

```
# once per tool version
QUESTA_BIN=<questa>/bin vivado -mode batch -source tools/compile_simlib.tcl

# IP and block design (per unit, if used)
vivado -mode batch -source designs/<name>/tcl/build_ip.tcl
vivado -mode batch -source designs/<name>/bd/build_bd.tcl

# test plan lint (no EDA)
python3 tools/make_report.py --check designs/<name>

# tests, one by one + report
bash tools/run_tests.sh <name>                         # all
bash tools/run_tests.sh <name> questa T02 T05          # selected
RANDOM_SEED=<n> bash tools/run_tests.sh <name> questa T01   # reproduce a seed
MAKE_ARGS="WAVES=1" bash tools/run_tests.sh <name> questa T01

# quick smoke while iterating (all tests, one run; never counts for validation)
bash tools/run_sim.sh <name>            # or: bash tools/run_sim.sh <name> ghdl

# SV/UVM path
vsim -c -do designs/<name>/sim/run_sim.tcl

# OOC synth check (fpga-auto writes build/synth_sources.tcl)
bash tools/run_synth_check.sh <name>

# top-level build
vivado -mode batch -source designs/<top>/impl/build.tcl

# after editing CLAUDE.md or .claude/
bash tools/sync_agents.sh
```

---

## Examples

- `designs/axis_fifo_loopback` — leaf: AXI-Stream CDC FIFO (`axis_fifo_ctrl`
  + `xpm_fifo_async`), test plan T01–T04. Status `generated`; plan and test
  plan awaiting approval.
- `designs/ddc_channelizer` — composite skeleton (DDS, CMPY, CIC, FIR) reusing
  `axis_fifo_loopback`; `planned`, blocked at gate 1 until its dependency is
  validated.

## Extending

- **Add a role:** create `.claude/skills/<name>/SKILL.md` (front-matter `name`
  + `description`), add it to the skills table in `CLAUDE.md`, then run
  `bash tools/sync_agents.sh`.
- **Add an isolated worker:** `.claude/agents/<name>.md` (mirror it into
  `tools/sync_agents.sh` if Antigravity needs it).
- **Share across projects:** package the skills/agents as a Claude Code plugin.
