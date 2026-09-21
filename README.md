# Logic-Spec
Framework for AI based FPGA Design 

# FPGA Spec-Driven Design Framework (for Claude Code)

A **spec-driven, plan-gated FPGA design framework** delivered as Claude Code
**skills + rules**. Claude generates the design — vendor IP configuration, custom
VHDL, and cocotb testbenches — plus the scripts to build and simulate it. **You
run Questa and Vivado yourself** by executing the generated scripts. Claude never
runs an EDA tool; it prepares the scripts and waits for your results.

---

## Mental model

Three layers work together:

- **Rules — `CLAUDE.md`.** Auto-loaded by Claude Code every session. Holds the
  hard rules: the plan gate, VHDL-primary/vendor/cocotb-on-Questa policy, and the
  "EDA execution is manual" rule.
- **Skills — `.claude/skills/`.** The workflow roles, each invocable as a slash
  command (`/fpga-architect`, `/fpga-plan`, …) or auto-invoked by Claude when the
  context fits. These are where generation happens.
- **Subagent — `.claude/agents/fpga-critic.md`.** An isolated worker for deep
  sim-log/waveform analysis, so failure diagnosis doesn't clutter the main
  context.

Templates you run by hand live in `templates/`. The full rationale for every
design decision is in `docs/framework-design-spec.md`.

---

## Install

1. Copy this whole folder into your project root (e.g.
   `C:\Dropbox\projects\work\AI_HDL\AI_SpecDesign\fpga-spec`).
2. Open that folder in **Claude Code**. `CLAUDE.md` loads automatically and the
   skills under `.claude/skills/` are discovered on startup.
3. Verify: type `/` — you should see the `fpga-*` skills in the menu.

**Tooling you need locally** (Claude never invokes these — you do):
Vivado, Questa, and cocotb (`pip install cocotb`).

---

## The workflow

```
/fpga-architect  → designs/<name>/spec.md      requirements + vendor
/fpga-plan       → designs/<name>/plan.md       PENDING → you approve → APPROVED   ← GATE
   ── nothing below runs until plan.md is APPROVED ──
/fpga-ip         → tcl/build_ip.tcl             then: vivado -mode batch -source …
/fpga-blockdesign→ bd/build_bd.tcl              then: vivado -mode batch -source …   (Xilinx)
/fpga-rtl        → rtl/*.vhd
/fpga-testbench  → tb/*.py + tb/Makefile        (cocotb — written first)
/fpga-questa     → sim scripts + one-time lib compile
   ── you run the sim, paste results back ──
/fpga-review     → diagnosis + targeted fix → you re-run
```

### Step by step

1. **Architect.** `/fpga-architect "1G Ethernet loopback with an AXI-Stream FIFO"`
   → writes `spec.md` (requirements, vendor, abstract IP, acceptance criteria).
2. **Plan (the gate).** `/fpga-plan` → writes `plan.md` with `status: pending`
   and asks you to approve. Read it; when happy, tell Claude to approve (it sets
   `status: approved`). **No code is generated before this.**
3. **IP + block design.** `/fpga-ip` then `/fpga-blockdesign` write the Vivado
   Tcl. Run them yourself:
   ```
   vivado -mode batch -source designs/<name>/tcl/build_ip.tcl
   vivado -mode batch -source designs/<name>/bd/build_bd.tcl
   ```
4. **RTL + testbench.** `/fpga-rtl` writes VHDL; `/fpga-testbench` writes the
   cocotb tests (from the acceptance criteria) and the run `Makefile`.
5. **Questa scripts.** `/fpga-questa` writes the one-time library-compile script
   and confirms the run Makefile. Run manually:
   ```
   vivado -mode batch -source designs/<name>/sim/compile_simlib.tcl   # once per tool version
   cd designs/<name>/tb && make                                        # each run (cocotb)
   ```
6. **Review + repair.** Paste `results.xml` / the transcript into `/fpga-review`.
   Claude diagnoses (delegating to `fpga-critic` for deep logs), applies a minimal
   fix, and tells you the command to re-run. Loop until green.

---

## The plan gate

The gate is the framework's core discipline: **no RTL, IP, block design,
testbench, or EDA script is generated until `designs/<name>/plan.md` is marked
`status: approved`.** It's enforced two ways — the rule in `CLAUDE.md`, and a
gate check at the top of every generation skill. If you ask a generation skill to
run early, it will stop and point you back to `/fpga-plan`.

---

## Design directory layout

```
designs/<name>/
  spec.md      requirements + vendor            (fpga-architect)
  plan.md      the approved plan                 (fpga-plan)  ← gate
  rtl/         custom VHDL                        (fpga-rtl)
  tb/          cocotb tests + Makefile            (fpga-testbench)
  tcl/         Vivado IP generation Tcl           (fpga-ip)
  bd/          Xilinx block design Tcl            (fpga-blockdesign)
  sim/         run scripts, results.xml, logs     (fpga-questa)
```

---

## Design decisions (short form)

- **VHDL-primary**; Verilog/SV only where a vendor IP forces it. Mixed-language
  sim under Questa is expected.
- **Vendor (Xilinx/Altera) chosen from requirements**, IP kept abstract until
  then so the choice is late-bound.
- **Verification-first with cocotb on Questa** — Python testbenches make the
  repair loop robust and give clean `results.xml`; UVM stays available for
  sign-off.
- **EDA execution is manual** — every tool run is a prepared script you invoke,
  so you stay in control of Vivado/Questa.

---

## Manual command cheat-sheet

```
# one-time, per Questa/Vivado version
vivado -mode batch -source designs/<name>/sim/compile_simlib.tcl

# generate/config IP and block design
vivado -mode batch -source designs/<name>/tcl/build_ip.tcl
vivado -mode batch -source designs/<name>/bd/build_bd.tcl

# simulate (cocotb, default)
cd designs/<name>/tb && make

# simulate (SV/UVM path)
vsim -c -do designs/<name>/sim/run_sim.tcl
```

---

## Extending

- **Add a role:** create `.claude/skills/<name>/SKILL.md` (frontmatter `name` +
  `description`); it becomes `/<name>` and auto-invocable. Add it to the table in
  `CLAUDE.md`.
- **Add an isolated worker:** drop a `.claude/agents/<name>.md` subagent.
- **Share across projects:** this scaffold can later be packaged as a Claude Code
  **plugin** (a marketplace bundle of these same skills/agents) if you want to
  reuse it in other repos — not needed for a single project.
