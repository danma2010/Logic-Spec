# FPGA Design Framework — Design Specification

**Status:** Draft v0.1 (approved plan)
**Author:** Dan
**Purpose:** A multi-agent, spec-driven framework that generates FPGA designs — vendor IP configuration and custom RTL — plus their testbenches, and drives functional verification through Questa, all under a mandatory plan-before-code gate.

This document is the framework's own first artifact: the framework requires a written plan before any code, and this spec is that plan for the framework itself.

---

## 1. Scope

### Goals
- Take a natural-language design request and produce a **simulation-passing FPGA design**: configured vendor IP + custom RTL, wired together, with a testbench that verifies it.
- Support **AMD/Xilinx and Altera/Intel** targets, selected from the architecture requirements.
- Run a closed **generate → simulate → repair** loop driven by real EDA-tool feedback, not by the agent guessing.
- Always present a **design plan for human approval before writing code**.

### Non-goals (v1)
- Timing closure / place-and-route sign-off (synthesis + PPA is a later phase).
- Full UVM sign-off environments (available as an option, not the default).
- Physical hardware bring-up / on-board debug.

---

## 2. HDL & language policy

- **Custom RTL: VHDL-primary.** The RTL Designer agent writes VHDL by default.
- **Verilog/SystemVerilog: only when forced** — i.e. a vendor IP core is only available in (or must be instantiated as) Verilog/SV. This is treated as an unavoidable exception, not a choice.
- **Mixed-language simulation is expected regardless**, because vendor IP frequently ships as encrypted Verilog/SV. Questa handles the mixed-language elaboration; the top level stays VHDL.

---

## 3. Vendor targeting & IP abstraction

- Vendor (**Xilinx** or **Altera**) is decided at the **architecture stage**, from the requirements, not hard-coded.
- IP requirements are expressed **abstractly** first — e.g. "dual-clock FIFO, 512 × 64," "DDR4 controller," "GT transceivers" — and the IP-Core agent **resolves the abstract requirement to the concrete vendor IP** at generation time. This late binding (inspired by LiteX's vendor-neutral platform model) keeps the architecture free of vendor lock-in and makes a vendor switch a re-resolve rather than a rewrite.

---

## 4. Pipeline (phase-gated)

```
1. Spec & Architecture   → structured requirements + vendor target
2. Design Plan           → full plan presented for approval   ⟵ HARD GATE, no code before approval
3. Generation            → IP config + block design + custom RTL + testbench
4. Simulation            → Questa (Tcl-driven), structured results
5. Repair                → Critic reads results, loops to 3
6. Synthesis / PPA       → later phase
```

**The plan gate (step 2) is a first-class feature.** Before any code is generated, the Orchestrator assembles and presents: module hierarchy, IP selection + configuration, block-design topology (Xilinx), testbench strategy, and simulation setup. Generation does not begin until the plan is approved.

---

## 5. Agent roster

| Agent | Responsibility | Consumes | Produces |
|---|---|---|---|
| **Architect** | Turn NL request into structured requirements; choose vendor target | User request | Requirements doc, vendor target, machine-checkable acceptance criteria |
| **IP-Core** | Explore vendor catalog, configure, instantiate | Requirements + vendor | Configured IP + generation Tcl (`create_ip`/`qsys`) |
| **Block-Design** (Xilinx) | Assemble IP + custom RTL into a BD, in Tcl | IP set + RTL modules | IP Integrator BD Tcl, validated + wrapped |
| **RTL Designer** | Write custom logic modules | Plan + testbench | VHDL (Verilog only where forced) |
| **Verification** | Write the testbench **first**, from acceptance criteria | Acceptance criteria | cocotb test (default) or SV/UVM (optional) |
| **Simulation runner** *(tool, not LLM)* | Compile, elaborate, run, collect results | Design + testbench | `results.xml`, transcript, waveforms |
| **Critic / Debugger** | Read failures + waveforms, propose targeted repairs | Sim results | Repair actions → RTL Designer / IP-Core |
| **Orchestrator** | Own handoffs, phase gates, shared state | Everything | Plan, gate decisions, run state |

**Verification-first:** the Verification agent writes the testbench before the RTL exists, so the acceptance criteria act as the gate the RTL must pass. This is native to hardware and makes the repair loop meaningful.

---

## 6. Tool layer (the core engineering)

The tool layer is the deterministic bridge between agents and EDA tools. It is where most of the real work lives.

### 6.1 Questa driver (verification engine)
- Generates and runs Tcl: `vlib` / `vmap` → `vcom` (VHDL) / `vlog` (Verilog/SV) → `vopt` → `vsim … run -all`.
- **Vendor IP sim models** are compiled once via Vivado `compile_simlib` (Quartus has its equivalent) into Questa-usable libraries and referenced at elaboration with `-L`.
- **Retrieving results is structured, not scraped by eye:** the driver emits a machine-readable results file (pass/fail, assertion/error counts, coverage) that the Critic parses. With cocotb this is the xUnit-style `results.xml`; for UVM runs it is a parsed transcript summary.
- cocotb runs *inside* this same Tcl invocation — `vsim` is launched with the cocotb GPI library loaded and a `-do` script — so Tcl-driven control and cocotb are complementary, not competing.

### 6.2 Vivado driver (IP + block design)
- Non-project / Tcl mode.
- IP: `create_ip` → `set_property CONFIG.* …` → `generate_target`.
- Block design (IP Integrator): `create_bd_design` → `create_bd_cell` → `connect_bd_net` / `connect_bd_intf_net` → `validate_bd_design` → `make_wrapper`.

### 6.3 Quartus driver (Altera path)
- Platform Designer / Qsys system, scripted via Tcl; `qsys-generate` / `ip-generate` for IP.

---

## 7. Verification strategy

- **Engine:** Questa, always. cocotb and UVM are *testbench styles that ride on Questa*, not alternative engines.
- **Default testbench style: cocotb.** Rationale:
  - The Verification agent writes **Python instead of UVM** — LLMs produce correct Python far more reliably than correct UVM, so the repair loop burns fewer iterations on testbench syntax rather than real design bugs.
  - **Clean structured results** (`results.xml`) for the Critic to parse — directly satisfies the "retrieve results after simulation" requirement.
- **cocotb ↔ VHDL:** cocotb drives the DUT top through Questa's foreign-interface layer — VPI for Verilog, **FLI/VHPI for VHDL**. The VHDL top talks to cocotb via FLI; any Verilog/SV IP instantiated *inside* is Questa's concern and simulates normally. cocotb neither sees nor cares about the internals.
- **UVM optional:** cocotb is not UVM — it lacks UVM's constrained-random / factory / coverage machinery (pyuvm approximates but is not full SV-UVM). The framework is **dual-mode**: cocotb for the fast, agent-friendly block-level and IP-config loop; SV/UVM kept available for complex sign-off later. The Verification agent selects the style at the plan gate.

---

## 8. Orchestration substrate

- A **Python layer** that calls the **Claude API** for the agents and **shells out to Vivado / Quartus / Questa via Tcl** for the tool layer.
- Chosen because: (a) it gives deterministic control over tool invocation, which matters when the whole loop is Tcl-driven; (b) it matches the existing Python + Claude-API track; and (c) cocotb is Python too, so **one language covers orchestration and testbenches**.

---

## 9. Feedback loop mechanics

```
plan approved
   └─► Generation (IP + BD + RTL + cocotb tb)
          └─► Questa driver: build → elaborate (-L vendor libs) → run
                 └─► results.xml + transcript
                        ├─ pass → done (→ optional synth/PPA)
                        └─ fail → Critic reads results + waveform
                                     └─► targeted repair → Generation
```

The loop is deterministic because every iteration ends in a parsed, structured result — never an agent eyeballing a log.

---

## 10. Proposed repo layout

```
fpga-agent-framework/
  framework/
    orchestrator.py
    agents/            architect · ip_core · block_design · rtl_designer · verification · critic
    drivers/           questa.py · vivado.py · quartus.py
    ip/                abstract-requirement schema + vendor catalog mappings
    llm/               claude api client
    plan/              plan-gate enforcement
  designs/             per-design working dirs (generated)
    <design>/
      spec.md · plan.md
      rtl/   tb/(cocotb)   tcl/   bd/(xilinx)   sim/(results.xml, transcripts, waveforms)
  docs/
    framework-design-spec.md   ← this file
```

---

## 11. Risks & things to validate hands-on

- **cocotb + VHDL via FLI/VHPI** is the one item to prove out once on the specific Questa version before committing — library build and correct `-foreign` hookup are a known setup wrinkle. It works; it just shouldn't be taken on faith.
- **Encrypted vendor IP** may not simulate outside the vendor's own model set — the `compile_simlib` → `-L` path must be verified per IP.
- **cocotb coverage** is weaker than UVM; complex sign-off will need the UVM path.

---

## 12. Roadmap

- **v1** — VHDL custom RTL + Xilinx IP/BD, cocotb testbenches, Questa Tcl driver with structured results, plan gate, single-vendor (Xilinx) end-to-end.
- **v2** — Altera path (Platform Designer), abstract-IP resolution across both vendors.
- **v3** — Synthesis + PPA feedback into the loop; optional UVM sign-off mode.
