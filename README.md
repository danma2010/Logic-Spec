# Logic-Spec

**A spec-driven, gated, hierarchical FPGA design framework for coding agents.**

You write the requirements. The agent reviews them, asks about whatever is
missing, and turns the refined spec into an architecture, a plan, a test plan,
VHDL, vendor-IP Tcl and cocotb testbenches, plus the scripts to build and
simulate them. **You run Questa and Vivado**, or you opt in to `fpga-auto`,
which may run simulation and an OOC synth check for you. Nothing moves forward
without your approval at four gates.

Works with **Claude Code** and **Antigravity**.

---

## Contents

1. [Concepts](#1-concepts)
2. [Install (once)](#2-install-once)
3. [The workflow at a glance](#3-the-workflow-at-a-glance)
4. [Walkthrough: from spec to validated unit](#4-walkthrough-from-spec-to-validated-unit)
5. [Building a hierarchy and the FPGA top](#5-building-a-hierarchy-and-the-fpga-top)
6. [Automatic mode (opt-in)](#6-automatic-mode-opt-in)
7. [When something changes](#7-when-something-changes)
8. [Reference](#8-reference)
9. [Maintaining the framework](#9-maintaining-the-framework)

---

## 1. Concepts

### Framework vs. design

| | What | Where |
|---|---|---|
| **Framework** | rules, skills, tools, templates, shared simulation libraries | this repository, installed once user-wide (`$LS` below) |
| **Design** | one FPGA unit: its spec, documents, RTL, testbench, scripts | **its own folder, anywhere on disk** — one design = one folder |

A design folder never lives inside the framework (except `examples/`). It
loads the framework rules through two small **pointer files** at its root:
`CLAUDE.md` (Claude Code) and `AGENTS.md` (Antigravity).

### Inside a design folder

```
my_design/
  CLAUDE.md  AGENTS.md     pointers to the framework rules
  spec/                    ALL documents: spec.md, spec_work.md, architecture.md,
                           plan.md, testplan.md, design_log.md
  rtl/ tb/ tcl/ bd/ sim/   code and scripts, beside spec/
  xdc/ impl/ build/
```

### Units and hierarchy

Every design is a **unit** of one `kind`:

- `leaf` — custom RTL and vendor IP only;
- `composite` — also instantiates other, **validated** units;
- `top` — the composite that is the FPGA top; its interface is the pins.

A unit is reused by **direct RTL instantiation** of its `top` entity. A
dependency is another design folder, written as a **relative path** (e.g.
`../axis_fifo_loopback`).

### Unit status

```
planned  ──fpga-rtl──▶  generated  ──gate 3──▶  validated
(architecture written)  (RTL written)            (all must tests PASS)
        ▲                                               │
        └──────────── any change to rtl/, tb/, IP Tcl, testplan ─┘ (back to generated)
```

Only a `validated` unit may be instantiated by another unit.

### The four gates

| Gate | File | Blocks | Approved when |
|---|---|---|---|
| **0 — Spec** | `spec/spec_work.md` | every other step | you approve the refined spec, and `spec.md` hasn't changed since |
| **1 — Plan** | `spec/plan.md` | all code generation | you approve the plan, and every dependency is `validated` |
| **2 — Test plan** | `spec/testplan.md` | testbench code | you approve the test list; every `AC-n` has a `must` test |
| **3 — Validation** | `sim/test_report.md` | reuse by other units | every `must` test PASSes on current sources, default configuration |

Each document gate uses `status: pending → approved` in the file's
front-matter. **Any edit to an approved document puts it back to `pending`.**

---

## 2. Install (once)

Prerequisites: Git Bash (on Windows), Python 3, and for running simulations
yourself: Questa, Vivado, cocotb (`pip install cocotb`).

```bash
# 1. clone the framework anywhere
git clone <repo-url> C:/tools/Logic-Spec
LS=C:/tools/Logic-Spec

# 2. install it user-wide
bash $LS/tools/install.sh

# 3. once per Vivado/Questa version: compile the shared vendor sim libraries
QUESTA_BIN=<questa>/bin vivado -mode batch -source $LS/tools/compile_simlib.tcl
#   optional: FAMILY=artix7 to compile one family only (much faster)
```

`install.sh` copies:

| What | To |
|---|---|
| rules (`CLAUDE.md`, `AGENTS.md`) | `~/.logic-spec/` |
| Claude Code skills `fpga-*` and the `fpga-critic` agent | `~/.claude/skills/`, `~/.claude/agents/` |
| Antigravity skills `fpga-*` | `~/.gemini/antigravity/skills/` (override with `AG_SKILLS_DIR=…`) |

It fills the framework path into every copy and never deletes anything.
**Re-run it whenever the framework changes** (e.g. after `git pull`).

---

## 3. The workflow at a glance

```
 you                          agent skill            output (in the design folder)
 ───                          ───────────            ─────────────────────────────
 write spec/spec.md     ──▶   fpga-spec        ──▶   spec/spec_work.md     ◀── GATE 0 (you approve)
                              fpga-architect   ──▶   spec/architecture.md
                              fpga-plan        ──▶   spec/plan.md          ◀── GATE 1 (you approve)
                              fpga-testplan    ──▶   spec/testplan.md      ◀── GATE 2 (you approve)
                              fpga-ip          ──▶   tcl/build_ip.tcl
                              fpga-blockdesign ──▶   bd/build_bd.tcl       (optional)
                              fpga-rtl         ──▶   rtl/*.vhd             status: generated
                              fpga-testbench   ──▶   tb/*.py, tb/Makefile
                              fpga-questa      ──▶   sim/RUN.md
 run the tests          ──▶   (you)            ──▶   sim/test_report.md
                              fpga-review      ──▶   fixes … status: validated  ◀── GATE 3
 ── at the top level ──
                              fpga-toplevel    ──▶   xdc/*.xdc, impl/build.tcl
 run the build          ──▶   (you)            ──▶   bitstream
```

How to invoke a skill: in Claude Code type `/fpga-spec` (or just ask, e.g.
"review my spec"); in Antigravity ask for it by name. **Always open the design
folder itself** as the workspace, so the pointer files load the rules.

---

## 4. Walkthrough: from spec to validated unit

The running example is a reusable clock-domain-crossing AXI-Stream FIFO,
`axis_fifo_loopback` (the finished files are in
`examples/axis_fifo_loopback`). Commands run from the design folder; `$LS` is
the framework folder.

### Step 0 — Create the design folder and write the spec

```bash
mkdir -p D:/fpga/axis_fifo_loopback
bash $LS/tools/new_design.sh D:/fpga/axis_fifo_loopback --template
```

This creates `spec/spec.md` (a checklist template), the pointer files and a
`.gitignore`. Fill in `spec/spec.md` in your own words. Free-form is fine:

```markdown
## Purpose
A clock-domain-crossing AXI-Stream loopback: words written on the s_axis clock
are buffered and read out, in order, on the m_axis clock.

## Interfaces
- s_axis (slave) and m_axis (master), each with its own aclk / aresetn.
- Data width 64 bits by default; must be adjustable when reused.

## Functional requirements
- Every word appears exactly once on m_axis, in order.
- Full buffer → s_axis_tready low. Empty buffer → m_axis_tvalid low.
...
```

> Shortcut: skip `new_design.sh`, open an empty folder, and describe the
> design to the agent. `fpga-spec` creates the folder structure and saves
> your words verbatim as `spec/spec.md`.

`spec/spec.md` is **your** file. The framework never modifies it.

### Step 1 — `fpga-spec`: review, questions, refined spec (gate 0)

Open `D:/fpga/axis_fifo_loopback` in Claude Code or Antigravity and run
`fpga-spec`. The agent checks the spec against a 12-point list (scope,
interfaces, clocks, resets, behaviour, performance, resources, target,
HDL/simulator, reuse, verification, measurability). Then it asks you
**numbered questions**, each with a proposed default:

```
Q-1 (blocking)  Resets: are s_axis_aresetn / m_axis_aresetn synchronous to their
                own clocks, active-low? Default: yes, sync, active-low.
Q-2 (blocking)  Clock ranges: which frequencies must s_aclk and m_aclk support?
                Default: 50–250 MHz each, any ratio, fully asynchronous.
Q-3 (non-blocking)  DATA_WIDTH range when reused? Default: 8–512, multiple of 8.
Q-4 (non-blocking)  Read-side behaviour: first-word fall-through? Default: yes.
Q-5 (non-blocking)  HDL / simulator: VHDL-2008 + Questa/cocotb? Default: yes.
```

You answer, e.g. "Q-1 default, Q-2 100 and 150 MHz, others default." The
agent then writes `spec/spec_work.md`:

```markdown
---
status: pending
source: spec/spec.md
spec_sha256: 9f2c…          # fingerprint of spec.md at review time
date: 2026-11-04
---
## Requirements
| ID | Requirement (measurable) | Category | Type | Source |
|---|---|---|---|---|
| R-0 | Words written on s_axis are read out on m_axis across two independent clocks | purpose | stated | spec §Purpose |
| R-1 | s_axis_aclk runs at 100 MHz, m_axis_aclk at 150 MHz, asynchronous | clock | stated | Q-2 |
| RR-2 | Resets are synchronous to their own clock, active-low | reset | assumed | default (Q-1) |
| R-3 | Every word written appears exactly once on m_axis, in order, bit-exact | function | stated | spec §Functional requirements |
| RR-4 | The FIFO needs a gray-coded / XPM-style CDC between the two clocks | function | derived | from R-0, R-1 |
| ... | | | | |
## Clarifications log
| Q | Question | Answer | Blocking | Resulting req |
|---|---|---|---|---|
| Q-1 | Reset type and polarity | default: sync, active-low | yes | RR-2 |
| Q-2 | Clock frequencies | 100 MHz (s), 150 MHz (m), asynchronous | yes | R-1 |
...
## Open items (non-blocking)
- (none)
```

Requirement IDs come from **one shared counter starting at 0**: `R-n` is
something you stated (in `spec.md` or as an answer), `RR-n` is something the
agent derived or a default you accepted. The agent lists every RR when it asks
for approval, because those are the requirements you didn't write yourself.
IDs never change; a dropped requirement is marked `withdrawn`.

**You review `spec_work.md` and approve it** (say "approved"). The agent sets
`status: approved`. From now on, **every step reads `spec_work.md`, not
`spec.md`**.

### Step 2 — `fpga-architect`: architecture and acceptance criteria

The agent derives `spec/architecture.md`: the manifest plus the structured
architecture. No code is written yet.

```yaml
---
name: axis_fifo_loopback
vendor: xilinx
part: xc7a35ticsg324-1L
kind: leaf
top: axis_fifo_loopback
status: planned
dependencies: []
ports:
  - { name: s_axis_tdata, dir: in, width: DATA_WIDTH }
  ...
validated: {}
---
```

It also writes numbered, measurable **acceptance criteria**, traced to the
requirements:

```markdown
- **AC-1** GIVEN a stream of N words on s_axis WHEN they are read out on m_axis
  THEN all N arrive exactly once, in order, bit-exact.   (R-3)
- **AC-2** GIVEN the FIFO is full WHEN s_axis_tvalid is asserted THEN
  s_axis_tready is deasserted.                           (R-5)
```

Vendor IP stays **abstract** here ("dual-clock FIFO 512 × DATA_WIDTH").

### Step 3 — `fpga-plan`: the design plan (gate 1)

The agent writes `spec/plan.md` (`status: pending`) with these sections:

1. **Module hierarchy**: the top `rtl/axis_fifo_loopback.vhd`, with
   `axis_fifo_ctrl` beneath it.
2. **IP resolution**: the abstract FIFO resolved to `xpm_fifo_async`, so the
   width can follow a VHDL generic.
3. **Block design**: none in this example.
4. **Verification strategy**: cocotb on Questa; the default configuration
   uses the real top and the XPM model; `FAST=1` swaps in a behavioural FIFO
   for quick iteration only.
5. **Simulation setup**: compile order and the shared `simlibs`.

**You review and approve.** No RTL, IP, BD, testbench or Tcl can be generated
before this.

### Step 4 — `fpga-testplan`: the test collection (gate 2)

The agent breaks the unit into features and writes `spec/testplan.md`, one
row per cocotb test:

| ID | Function | AC | Priority | Pass criterion |
|---|---|---|---|---|
| T01 | t01_order_integrity | AC-1, AC-4 | must | 1024 random words, s 10 ns / m 7 ns, 20 % random stalls: received == sent (count, order, bit-exact) |
| T02 | t02_backpressure_full | AC-2, AC-1 | must | consumer stalled: `s_axis_tready` low after N words, DEPTH-8 ≤ N ≤ DEPTH+4 … |
| T03 | t03_empty_tvalid_low | AC-3 | must | after reset, `m_axis_tvalid` = 0 for 200 cycles … |
| T04 | t04_cdc_fast_writer | AC-4, AC-1, AC-2 | must | s 4 ns / m 13 ns, 2048 words: received == sent … |

Lint it (no EDA needed):

```bash
python3 $LS/tools/make_report.py --check .
#   TESTPLAN OK: 4 tests (4 must), 0 error(s)
```

**You review and approve.** Pass criteria are now fixed. They are never
loosened to make a test pass, and any later edit sends the test plan back to
`pending`.

### Step 5 — `fpga-ip` / `fpga-blockdesign`: vendor IP (if any)

For configured cores, the agent writes `tcl/build_ip.tcl` and prints the
command. You run it:

```bash
vivado -mode batch -source tcl/build_ip.tcl
```

(This example uses an XPM macro, which needs no generation step.
`fpga-blockdesign` runs only when the plan wires IP in a Xilinx block design
inside the unit.)

### Step 6 — `fpga-rtl` + `fpga-testbench`: code

- `fpga-rtl` writes VHDL-2008 into `rtl/`: `axis_fifo_ctrl.vhd`, plus
  `axis_fifo_loopback.vhd` as the unit top. It sets the status to
  `generated`.
- `fpga-testbench` writes `tb/test_axis_fifo_loopback.py` with exactly one
  `@cocotb.test` per test-plan row, using the same function names and the pass
  criteria as assertions. It also writes `tb/Makefile`.

### Step 7 — `fpga-questa` + you: run the tests

`fpga-questa` writes `sim/RUN.md` and prints the commands. You run the
standard runner. Each test runs in its own simulator invocation, in plan
order:

```bash
bash $LS/tools/run_tests.sh .
#  T01  t01_order_integrity        must  ... done
#  T02  t02_backpressure_full      must  ... FAIL
#  T03  t03_empty_tvalid_low       must  ... done
#  T04  t04_cdc_fast_writer        must  ... done
#  REPORT FAIL: must 3/4, should 0/0 -> sim/test_report.md
```

The result is `sim/test_report.md`: per-test PASS/FAIL/ERROR/STALE, seed,
log link (`sim/tests/<ID>.log`), acceptance-criteria coverage and the gate-3
verdict.

### Step 8 — `fpga-review`: repair and validate (gate 3)

Tell the agent "review the test report". `fpga-review` takes the failing tests
in plan order. It diagnoses each one against its pass criterion and hands deep
log analysis to `fpga-critic`. Then it applies a **minimal** fix and prints
the re-run command:

```bash
bash $LS/tools/run_tests.sh . questa T02                  # re-run one test
RANDOM_SEED=1234 bash $LS/tools/run_tests.sh . questa T02 # reproduce a seed
```

Repeat until a **full, default-configuration** run reports
`PASS — meets the validation gate`. The agent then stamps the manifest:

```yaml
status: validated
validated: { date: 2026-11-05, tests: "4/4 must PASS", report: sim/test_report.md }
```

The unit can now be reused.

---

## 5. Building a hierarchy and the FPGA top

### A composite unit

Create a sibling design folder, e.g. `D:/fpga/ddc_channelizer`, and run
steps 0–8 for it. In step 2 the architect finds the reusable unit, and you can
also name it in your spec. It records the reuse as a relative path:

```yaml
kind: composite
dependencies:
  - ../axis_fifo_loopback
```

- Gate 1 refuses to approve the plan until `../axis_fifo_loopback` is
  `validated`.
- `fpga-rtl` instantiates its top entity
  (`entity work.axis_fifo_loopback generic map (DATA_WIDTH => …)`).
- The testbench and build scripts compile the dependency's
  `../axis_fifo_loopback/rtl/*.vhd` first (bottom-up).
- The composite's tests are **integration tests** over the whole subtree.

Typical folder arrangement:

```
D:/fpga/
  axis_fifo_loopback/   leaf        validated
  ddc_channelizer/      composite   dependencies: [../axis_fifo_loopback]
  radio_top/            top         dependencies: [../ddc_channelizer, …]
```

### The FPGA top

Give the highest unit `kind: top` and a **pin map** (port → package pin → IO
standard, plus clocks). Put the pins in its `spec.md` so `fpga-spec` checks
them. Once every dependency (transitively) is `validated`:

```bash
# fpga-toplevel writes xdc/<top>_pins.xdc and impl/build.tcl
#   (+ impl/run_sources.tcl: all RTL bottom-up, + impl/run_constraints.tcl)
bash $LS/tools/run_tests.sh .                     # top integration tests
vivado -mode batch -source impl/build.tcl         # synth → place → route → bitstream
```

Existing constraint and build files are patched, never overwritten.

---

## 6. Automatic mode (opt-in)

Invoke `fpga-auto` explicitly to let the agent run the verify loop itself:

```
run_tests.sh → read report → minimal fix → re-run … (max 5 iterations)
     → on PASS: OOC synth check (run_synth_check.sh)
     → summary → ASKS YOU to confirm → validated
```

Guardrails:

- functional simulation and an OOC synthesis check only (never
  implementation, bitstream or hardware);
- gates 0–2 still apply;
- every action is logged in `sim/auto_log.md`;
- it stops and hands back on an ambiguous or repeated failure, a port or
  test-plan change, or a timing/resource issue.

---

## 7. When something changes

| You change… | Effect | What to do |
|---|---|---|
| `spec/spec.md` | gate 0 breaks (fingerprint mismatch); the tools refuse to run tests | run `fpga-spec` again, then approve the updated `spec_work.md` |
| an approved `spec_work.md` | back to `pending` | approve it; `fpga-architect` re-derives the architecture and the plan goes back to `pending` |
| an approved `plan.md` | back to `pending` | review and approve again |
| an approved `testplan.md` | back to `pending`; existing results become STALE | approve, then re-run the tests |
| RTL / tb / IP Tcl of a `validated` unit | status back to `generated`; every unit that depends on it must be re-validated | re-run the tests, review |

Every generating skill records its stage in `spec/design_log.md` (newest
first), so you can always see where a design stands.

---

## 8. Reference

### Files of a design

| File | Role | Written by |
|---|---|---|
| `spec/spec.md` | your requirements; never modified | you |
| `spec/spec_work.md` | refined spec: requirements table (`R-n` stated / `RR-n` derived or assumed, one shared counter from 0), clarifications log, open items, spec fingerprint (gate 0) | `fpga-spec` |
| `spec/architecture.md` | manifest + architecture + `AC-n` (+ pin map); the only place `status` lives | `fpga-architect` (status: rtl/review/auto) |
| `spec/plan.md` | design plan (gate 1) | `fpga-plan` |
| `spec/testplan.md` | tests `T01…` with pass criteria (gate 2) | `fpga-testplan` |
| `spec/design_log.md` | stage log, newest first | every generating skill |
| `rtl/` | VHDL-2008; `rtl/<top>.vhd` is the unit top | `fpga-rtl` |
| `tb/` | cocotb tests + `Makefile` | `fpga-testbench` |
| `tcl/` | `build_ip.tcl`; generated IP in `tcl/ip/` | `fpga-ip` |
| `bd/` | `build_bd.tcl` (optional) | `fpga-blockdesign` |
| `sim/` | `RUN.md`, `run_sim.tcl` (UVM), `tests/<ID>.log/.xml`, `test_report.md/.json`, `auto_log.md` | `fpga-questa`, tools, `fpga-auto` |
| `build/` | OOC synth-check workspace | `fpga-auto` |
| `xdc/`, `impl/` | constraints + non-project build (top only) | `fpga-toplevel` |

### Skills

| Skill | Role | Produces |
|---|---|---|
| `fpga-spec` | review spec, ask, refine — gate 0 | `spec/spec_work.md` (+ folder scaffold) |
| `fpga-architect` | architecture, vendor, manifest, hierarchy | `spec/architecture.md` |
| `fpga-plan` | design plan — gate 1 | `spec/plan.md` |
| `fpga-testplan` | test collection — gate 2 | `spec/testplan.md` |
| `fpga-ip` | vendor IP configuration | `tcl/build_ip.tcl` |
| `fpga-blockdesign` | Xilinx BD inside a unit | `bd/build_bd.tcl` |
| `fpga-rtl` | VHDL + sub-unit instantiation | `rtl/*.vhd` |
| `fpga-testbench` | cocotb tests from the test plan | `tb/*.py`, `tb/Makefile` |
| `fpga-questa` | sim scripts + run instructions | `sim/RUN.md` (+ `run_sim.tcl`) |
| `fpga-review` | repair failing tests — gate 3 | fixes, `status: validated` |
| `fpga-toplevel` | pins → constraints + build | `xdc/*`, `impl/*` |
| `fpga-auto` | opt-in automatic verify loop | `sim/test_report.md`, `sim/auto_log.md` |
| `fpga-critic` | read-only failure diagnosis | diagnosis only |

### Two test runners

| | `run_tests.sh` — **standard** | `run_sim.sh` — **quick smoke** |
|---|---|---|
| Runs | one simulator invocation **per test**, in plan order | **one** invocation for all tests |
| Gates checked | gate 0 + approved test plan, plan lint | none |
| Output | `sim/test_report.md/.json`: per test, seed, log, AC coverage, STALE, verdict | one line + `sim/last_sim.log` |
| Counts for validation | **yes** (full run, default configuration) | **never** |

Use `run_sim.sh` only for fast feedback while fixing, or to try another
cocotb simulator (`bash $LS/tools/run_sim.sh . ghdl`).

### Command cheat-sheet

```bash
# ---- once ----
bash $LS/tools/install.sh                                   # install / refresh
QUESTA_BIN=<questa>/bin vivado -mode batch -source $LS/tools/compile_simlib.tcl

# ---- new design ----
bash $LS/tools/new_design.sh <folder> --template

# ---- from the design folder ----
python3 $LS/tools/make_report.py --check .                  # lint test plan, gate 0, R/RR IDs
vivado -mode batch -source tcl/build_ip.tcl                 # IP (if any)
vivado -mode batch -source bd/build_bd.tcl                  # block design (if any)
bash $LS/tools/run_tests.sh .                               # all tests + report
bash $LS/tools/run_tests.sh . questa T02 T05                # selected tests
RANDOM_SEED=<n> bash $LS/tools/run_tests.sh . questa T01    # reproduce a seed
MAKE_ARGS="WAVES=1" bash $LS/tools/run_tests.sh . questa T01   # with waveforms
bash $LS/tools/run_sim.sh .                                 # quick smoke (not for validation)
vsim -c -do sim/run_sim.tcl                                 # SV/UVM path
bash $LS/tools/run_synth_check.sh .                         # OOC synth check
vivado -mode batch -source impl/build.tcl                   # top-level build
```

### Hard rules (summary)

The full rules are in `CLAUDE.md` / `AGENTS.md`:

- `spec.md` is read-only.
- Nothing runs before gate 0, no code before gate 1, no testbench before
  gate 2, no reuse before gate 3.
- The agent never runs EDA tools and never claims a run happened, except in
  `fpga-auto`.
- VHDL-2008 is the primary HDL, unless `spec_work.md` says otherwise.
- One vendor per unit.
- Generated Tcl resolves paths from its own location.
- Files are never deleted without your approval.

---

## 9. Maintaining the framework

| Path | Contents |
|---|---|
| `CLAUDE.md` | rules — **source of truth** |
| `AGENTS.md` | rules for Antigravity (generated) |
| `.claude/skills/fpga-*/SKILL.md` | skills — **source of truth** |
| `.claude/agents/fpga-critic.md` | read-only critic subagent |
| `.agents/skills/` | Antigravity copy (generated) |
| `tools/` | `install.sh`, `new_design.sh`, `run_tests.sh`, `run_sim.sh`, `run_synth_check.sh`, `make_report.py`, `compile_simlib.tcl`, `sync_agents.sh` |
| `templates/` | starting points the skills fill in (incl. `spec_work.md`, `design/` pointer files) |
| `docs/` | `framework-design-spec.md` (rationale), `LOOP.md` (verify loop) |
| `examples/` | example design folders in the standard layout |
| `simlibs/` | shared vendor simulation libraries (not in git) |

- **Edit** `CLAUDE.md` and `.claude/` only, then run
  `bash tools/install.sh`. It runs `tools/sync_agents.sh` first to regenerate
  the Antigravity copy, then reinstalls.
- In skills, refer to framework files as `{{LOGIC_SPEC}}/…`; the installer
  replaces this with the real path.
- **Add a role:** create `.claude/skills/fpga-<name>/SKILL.md` (front-matter
  `name` + `description`), add it to the skills table in `CLAUDE.md`, re-run
  `install.sh`. A removed skill must be deleted from the install folders by
  hand.
- **Add an isolated worker:** `.claude/agents/fpga-<name>.md` (mirror it in
  `tools/sync_agents.sh` if Antigravity needs it).

Rationale and design decisions: `docs/framework-design-spec.md`. The
generate → simulate → repair loop in detail: `docs/LOOP.md`.
