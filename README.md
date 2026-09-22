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

## Units & hierarchy

Every design is a **unit** with a manifest `designs/<name>/unit.md` — its
interface, `kind` (`leaf` / `composite` / `top`), `dependencies`, and `status`
(`planned → generated → validated`). The framework is **bottom-up**:

1. Build and **validate** leaf units (custom RTL + vendor IP).
2. Compose validated units into higher units by **direct RTL instantiation** —
   the child entity is instantiated in the parent and its sources compiled in.
3. Designate the highest unit `kind: top`; its interface is the FPGA's pins.

Two gates guard the flow: the **plan gate** (no code before an approved plan) and
the **validation gate** — *a unit may only be instantiated once its `unit.md` is
`status: validated`*, which `/fpga-review` stamps on a passing sim.

## The workflow

```
per unit
  /fpga-architect  → spec.md + unit.md    requirements, vendor, kind, deps
  /fpga-plan       → plan.md              PENDING → you approve → APPROVED   ← PLAN GATE
     ── nothing below runs until plan.md is APPROVED ──
  /fpga-ip         → tcl/build_ip.tcl     then: vivado -mode batch -source …
  /fpga-blockdesign→ bd/build_bd.tcl      then: vivado -mode batch -source …   (Xilinx)
  /fpga-rtl        → rtl/*.vhd            (instantiates validated sub-units)
  /fpga-testbench  → tb/*.py + Makefile   (cocotb — written first)
  /fpga-questa     → sim scripts
     ── you run the sim, paste results back ──
  /fpga-review     → fixes; on PASS → unit.md status = VALIDATED              ← VALIDATION GATE

at the top
  /fpga-toplevel   → xdc/<top>_pins.xdc   from the pin map in the top spec
                     impl/build.tcl       non-project flow that sources …
                       run_sources.tcl      (RTL hierarchy bottom-up + IP)
                       run_constraints.tcl  (read_xdc)
                     + top integration testbench & sim
                     then: vivado -mode batch -source designs/<top>/impl/build.tcl
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
6. **Review + repair + validate.** Paste `results.xml` / the transcript into
   `/fpga-review`. Claude diagnoses (delegating to `fpga-critic` for deep logs),
   applies a minimal fix, and tells you the command to re-run. On a **passing**
   run it stamps `unit.md` → `status: validated` — the unit can now be reused.
7. **Compose.** In a higher unit, `/fpga-architect` picks up the validated unit as
   a dependency and `/fpga-rtl` instantiates it directly. Repeat 1–6 for the
   composite (its testbench is an integration test over the whole subtree).
8. **Top level.** Mark the highest unit `kind: top` with a pin map in its
   `spec.md`, then `/fpga-toplevel` → constraints + the modular non-project build
   + a top integration sim. Run:
   ```
   vivado -mode batch -source designs/<top>/impl/build.tcl
   ```

---

## The plan gate

The gate is the framework's core discipline: **no RTL, IP, block design,
testbench, or EDA script is generated until `designs/<name>/plan.md` is marked
`status: approved`.** It's enforced two ways — the rule in `CLAUDE.md`, and a
gate check at the top of every generation skill. If you ask a generation skill to
run early, it will stop and point you back to `/fpga-plan`.

## The verify loop

The generate → simulate → repair loop — where the design is checked against
simulation, the manual Questa boundary, and the exact paste-back commands — is
documented in **`docs/LOOP.md`**. In short: your cocotb testbench does the
design-vs-expected check inside Questa; `/fpga-review` checks the result, fixes,
and stamps `validated`; the loop pauses on every manual run.

---

## Design directory layout

```
designs/<name>/
  unit.md      manifest: kind, status, deps, ports  (fpga-architect / fpga-review)
  spec.md      requirements + vendor (+ pin map if top)  (fpga-architect)
  plan.md      the approved plan                    (fpga-plan)  ← plan gate
  rtl/         custom VHDL                           (fpga-rtl)
  tb/          cocotb tests + Makefile               (fpga-testbench)
  tcl/         Vivado IP generation Tcl              (fpga-ip)
  bd/          Xilinx block design Tcl               (fpga-blockdesign)
  sim/         run scripts, results.xml, logs        (fpga-questa)
  xdc/         constraints (top only)                (fpga-toplevel)
  impl/        build.tcl + run_sources.tcl + run_constraints.tcl (top only)
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





## Notes
The check itself is split in two:

Inside the simulation (on your machine). The cocotb testbench (tb/*.py, written by /fpga-testbench from the spec's GIVEN/WHEN/THEN acceptance criteria) is what actually checks the design's behavior against expectation. That runs inside Questa when you execute make. The pass/fail verdict lands in results.xml + the transcript. This is the design-vs-expected comparison.
Around the simulation (in Claude). You paste results.xml/the transcript back, and /fpga-review is where the design is checked against the simulation result — it reads the verdict, correlates failures to plan.md and the acceptance criteria, delegates deep transcript/waveform analysis to the fpga-critic subagent, applies a minimal fix, and prints the re-run command. On a pass it stamps unit.md → status: validated. That skill is the loop controller.

So the full generate → simulate → repair loop is:
/fpga-rtl + /fpga-testbench  →  /fpga-questa  →  [ YOU run Questa ]  →  paste results  →  /fpga-review
         ▲                                                                                    │
         └──────────────────────  fix, then re-run ◄──────────────────────────────────────────┘



        