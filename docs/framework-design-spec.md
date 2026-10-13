# FPGA Design Framework — Design Specification

**Status:** v0.2 — aligned with the implemented framework (2026-10-12)
**Author:** Dan Mayaffit
**Purpose:** A spec-driven, gated, hierarchical framework in which a coding
agent generates FPGA designs — vendor IP configuration, custom RTL, test plans
and testbenches — and the scripts to build and verify them through Questa and
Vivado, under mandatory human approval gates.

> v0.1 proposed a Python orchestrator calling the Claude API. The framework is
> instead implemented as **agent skills + rules** (Claude Code and
> Antigravity); a standalone orchestrator remains a roadmap option (§11).

---

## 1. Scope

### Goals
- Turn a written requirement (`spec.md`) into a **validated FPGA unit**:
  configured vendor IP + custom RTL, with a planned test collection that
  passes in simulation.
- Build systems **bottom-up**: validated units are reused by higher units,
  up to a designated FPGA top with pins, constraints and a non-project build.
- Support **AMD/Xilinx and Altera/Intel** targets, chosen from requirements.
- Close a **generate → simulate → repair** loop on real EDA results, never on
  the agent's guesses.
- Keep the human in control: approval gates, manual EDA execution by default.

### Non-goals (current)
- Timing closure / place-and-route sign-off (the OOC synth check only proves
  synthesizability).
- Full UVM sign-off environments (available as an option, not the default).
- Hardware bring-up / on-board debug.

---

## 2. Implementation substrate

| Layer | Claude Code | Antigravity |
|---|---|---|
| Rules (always loaded) | `CLAUDE.md` | `AGENTS.md` (generated) |
| Workflow roles | `.claude/skills/fpga-*` | `.agents/skills/fpga-*` (generated) |
| Isolated failure analysis | `.claude/agents/fpga-critic.md` (subagent) | `fpga-critic` skill |

`CLAUDE.md` and `.claude/` are the single source of truth;
`tools/sync_agents.sh` regenerates the Antigravity copy so the platforms
cannot drift. Deterministic work (running tests, parsing results, building
reports, synth checks) lives in plain scripts under `tools/`, not in prompts.

---

## 3. Data model

Each unit is a directory `designs/<name>/`:

- `spec.md` — the user's **input**; never modified by the framework.
- `architecture.md` — the **manifest** (front-matter: `name, vendor, part,
  kind, top, status, dependencies, ports, validated`) plus the derived
  architecture and numbered acceptance criteria `AC-n`. The only place a
  unit's status lives.
- `plan.md` (gate 1), `testplan.md` (gate 2), `design_log.md`,
  `sim/test_report.md` (evidence for gate 3).

**Status lifecycle:** `planned` → `generated` (RTL written) → `validated`
(gate 3). Any change to a validated unit's RTL, testbench, IP Tcl or test plan
returns it to `generated`; dependants must be re-validated.

**Hierarchy:** `leaf` → `composite` → `top`. Reuse is by **direct RTL
instantiation** of the child's `top` entity; the child's sources are compiled
into the parent. A unit's top is always an RTL entity — a block design may sit
inside a unit, never be its top. This keeps generics (e.g. data width)
available to parents and keeps the compile order explicit.

---

## 4. HDL & language policy

- **Custom RTL: VHDL-2008.**
- **Verilog/SystemVerilog only when forced** by a vendor IP.
- **Mixed-language simulation is expected** (vendor models are often
  Verilog/SV, e.g. XPM); Questa handles it, the unit top stays VHDL.

---

## 5. Vendor targeting & IP abstraction

- Vendor and part are decided at the **architecture stage** from requirements.
- IP is first expressed **abstractly** ("dual-clock FIFO 512×64, FWFT") and
  resolved to a concrete implementation at **plan** time — a configured core
  (`create_ip`, Platform Designer) or a parameterizable primitive (Xilinx XPM)
  when the size must follow a VHDL generic. A vendor switch is a re-resolve,
  not a rewrite.

---

## 6. Pipeline and gates

```
1. Input            spec.md (user)
2. Architecture     architecture.md: vendor, part, kind, top, deps, AC-n
3. Plan             plan.md                         ⟵ GATE 1 (approval; deps validated)
4. Test plan        testplan.md: T01…, pass criteria ⟵ GATE 2 (approval)
5. Generation       IP Tcl, BD Tcl, RTL, cocotb tests
6. Simulation       tools/run_tests.sh — one test per invocation → test_report.md
7. Repair           fpga-review (+ fpga-critic) → back to 5
8. Validation       all must tests PASS, current, default config ⟵ GATE 3
9. Top level        constraints + non-project build (+ top integration tests)
```

Gate 1 stops code before a reviewed plan. Gate 2 fixes *what "correct" means*
— measurable pass criteria traced to every `AC-n` — before any testbench code,
so a criterion is never loosened to get a pass. Gate 3 makes reuse safe.

---

## 7. Roles

| Role (skill) | Consumes | Produces |
|---|---|---|
| `fpga-architect` | `spec.md`, existing units | `architecture.md` |
| `fpga-plan` | architecture | `plan.md` (gate 1) |
| `fpga-testplan` | AC-n, plan | `testplan.md` (gate 2) |
| `fpga-ip` | plan | `tcl/build_ip.tcl` |
| `fpga-blockdesign` | plan, RTL | `bd/build_bd.tcl` (optional) |
| `fpga-rtl` | plan, validated sub-units | `rtl/*.vhd`, status `generated` |
| `fpga-testbench` | test plan | `tb/*.py`, `tb/Makefile` |
| `fpga-questa` | tb, IP | `sim/RUN.md`, `sim/run_sim.tcl` (UVM) |
| `fpga-review` | `sim/test_report.md` | fixes; status `validated` (gate 3) |
| `fpga-toplevel` | top architecture (pin map) | `xdc/*`, `impl/*` |
| `fpga-auto` | everything above | runs tests + synth check (opt-in) |
| `fpga-critic` | one failing test | diagnosis (read-only) |

**Verification-first:** the test plan is derived from the acceptance criteria
and the tests are written from the test plan, before or with the RTL.

---

## 8. Tool layer

### 8.1 Simulation (Questa)
- `tools/compile_simlib.tcl` compiles vendor libraries once per tool version
  into `simlibs/questa/` (shared by all units).
- `tb/Makefile` (cocotb) compiles sub-units bottom-up, then the unit; the
  default configuration uses the real top and real IP models.
- `tools/run_tests.sh` runs each test-plan entry in its own simulator
  invocation (`COCOTB_TEST_FILTER` / `TESTCASE`), keeping `sim/tests/<ID>.xml|.log`.
- `tools/make_report.py` lints the test plan against the ACs and the
  testbench, and builds `sim/test_report.md|.json` with seeds, AC coverage,
  STALE detection (sources newer than the result) and the gate-3 verdict.
- SV/UVM path: `sim/run_sim.tcl` (`vlib/vcom/vopt/vsim`), transcript summary.

### 8.2 Vivado (non-project / Tcl)
- IP: `create_project -in_memory` → `create_ip` → `CONFIG.*` → `generate_target`.
- BD: in-memory project → `create_bd_design` → cells/nets →
  `validate_bd_design` → `make_wrapper`.
- Top build: `impl/build.tcl` sources `run_sources.tcl` (bottom-up RTL + IP)
  and `run_constraints.tcl`; synth → opt → place → phys_opt → route → reports
  → bitstream (`write_device_image` for Versal).
- OOC synth check: `tools/run_synth_check.sh` (TOP/PART from the manifest).
- Every script resolves paths from its own location.

### 8.3 Quartus (Altera path)
- Platform Designer / `qsys-generate` / `ip-generate` via Tcl; QSF + SDC
  constraints.

---

## 9. Verification strategy

- **Engine:** Questa. cocotb and UVM are testbench styles on top of it.
- **Default: cocotb** — LLMs write correct Python far more reliably than UVM,
  so repair iterations go to design bugs, and xUnit results are machine-readable.
- **cocotb ↔ VHDL** through Questa FLI/VHPI; Verilog/SV IP inside the DUT is
  simulated natively by Questa.
- **Tests are a planned collection**: one cocotb test per test-plan row,
  `must`/`should` priority, measurable pass criteria, every AC covered.
- **Fast loop vs. validation:** behavioural stand-ins (e.g. a FIFO model) may
  speed iteration behind an opt-in make variable; validation uses the real top
  and real vendor models only.
- **UVM optional**, selected at the plan gate for complex sign-off.

---

## 10. Execution policy

EDA execution is **manual by default**: the agent prints exact commands and
waits for results. `fpga-auto` is the only exception, only when explicitly
invoked: functional simulation and OOC synthesis only, bounded iterations,
audit log, stop-and-hand-back on ambiguity, and user confirmation before
`validated`.

---

## 11. Risks & things to validate hands-on

- **cocotb + VHDL via FLI/VHPI** on the specific Questa version — prove once.
- **Vendor library mapping**: `simlibs/questa/modelsim.ini` must map `xpm`,
  `unisim`, … with absolute paths; verify on first use.
- **Encrypted vendor IP** may only simulate with the vendor's model set —
  verify the `compile_simlib` → `-L` path per IP.
- **cocotb version drift** (1.x `TESTCASE` vs. 2.x `COCOTB_TEST_FILTER`) is
  handled in `run_tests.sh`; testbenches avoid version-specific APIs.
- **cocotb coverage** is weaker than UVM; complex sign-off needs the UVM path.

---

## 12. Roadmap

- **v1 (now)** — VHDL + Xilinx IP/XPM/BD, cocotb test plans and per-test
  reports, three gates, hierarchy and top-level build, Claude Code +
  Antigravity, opt-in auto mode.
- **v2** — Altera path end-to-end; abstract-IP resolution catalogue for both
  vendors.
- **v3** — Timing/PPA feedback into the loop; optional UVM sign-off mode;
  optional standalone Python orchestrator over the same files and tools.
