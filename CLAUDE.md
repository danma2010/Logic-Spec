# FPGA Spec-Driven Design — Project Rules

This repo is a **spec-driven, plan-gated FPGA design framework** for Claude Code.
Claude generates the design (vendor IP config, custom RTL, testbenches) and the
scripts to build/simulate it. **The user runs Questa and Vivado manually** by
executing the generated scripts. Claude never runs EDA tools itself.

## The workflow

```
/fpga-architect  → spec.md         (requirements + vendor target)
/fpga-plan       → plan.md         (PENDING → user approves → APPROVED)   ← GATE
   ── nothing below runs until plan.md is APPROVED ──
/fpga-ip         → tcl/build_ip.tcl        (user runs in Vivado)
/fpga-blockdesign→ bd/build_bd.tcl         (user runs in Vivado, Xilinx)
/fpga-rtl        → rtl/*.vhd
/fpga-testbench  → tb/*.py + tb/Makefile   (cocotb, verification-first)
/fpga-questa     → sim scripts             (user runs in Questa)
   ── user runs the sim, pastes results back ──
/fpga-review     → diagnose + repair → user re-runs
```

## HARD RULES

1. **Plan gate.** Never generate RTL, IP, block-design, testbench, or EDA Tcl
   until `designs/<name>/plan.md` exists **and** its front-matter says
   `status: approved`. If it doesn't, run `/fpga-plan` or ask the user to
   approve — then stop. Every generation skill re-checks this before doing
   anything.
2. **EDA execution is manual.** Claude produces scripts (Vivado Tcl, Questa
   Makefile/Tcl) but **must not** claim to have run them. Always print the exact
   command for the user to run, then wait for pasted results.
3. **HDL policy.** Custom RTL is **VHDL-primary**. Use Verilog/SystemVerilog
   **only** where a vendor IP core forces it. Mixed-language simulation under
   Questa is expected because vendor IP often ships as encrypted Verilog/SV.
4. **Vendor.** Choose exactly one target (**Xilinx** or **Altera**) at the
   architecture stage, justified by requirements. Keep IP **abstract**
   (e.g. "dual-clock FIFO 512×64") until then, so the vendor stays late-bound.
5. **Verification-first.** Write the testbench from the acceptance criteria
   before/with the RTL. Default is **cocotb on Questa**; use SV/UVM only if the
   plan explicitly flags it.
6. **Never delete files without explicit user approval.**

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

## Skills

| Skill | Role | Produces |
|---|---|---|
| `/fpga-architect` | requirements + vendor | `spec.md` |
| `/fpga-plan` | the plan + approval gate | `plan.md` |
| `/fpga-ip` | resolve/config vendor IP | `tcl/build_ip.tcl` |
| `/fpga-blockdesign` | Xilinx BD in Tcl | `bd/build_bd.tcl` |
| `/fpga-rtl` | custom VHDL | `rtl/*.vhd` |
| `/fpga-testbench` | cocotb testbench (first) | `tb/*.py`, `tb/Makefile` |
| `/fpga-questa` | Questa run scripts | `sim/*` |
| `/fpga-review` | read results, repair | fixes |

Subagent `fpga-critic` handles isolated sim-log/waveform analysis.

Full rationale for every decision: `docs/framework-design-spec.md`.
