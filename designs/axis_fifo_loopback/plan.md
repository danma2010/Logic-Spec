---
status: pending
---

# axis_fifo_loopback — Design Plan

> Revised 2026-10-12 (framework consistency review): FIFO resolved to
> `xpm_fifo_async` instead of a FIFO Generator core + block design, so the unit
> has an RTL top with a `DATA_WIDTH` generic and can be reused by direct RTL
> instantiation. Content changed → back to `pending` for approval.

## 1. Module hierarchy

- `axis_fifo_loopback` — unit top, `rtl/axis_fifo_loopback.vhd`
  - `axis_fifo_ctrl` — custom VHDL, AXI-Stream ⇄ FIFO handshake glue
    (`rtl/axis_fifo_ctrl.vhd`, unchanged)
  - `xpm_fifo_async` — XPM macro
- No sub-units.

## 2. IP selection & configuration

Abstract "dual-clock FIFO 512×64, FWFT" → **`xpm_fifo_async`**:
`FIFO_MEMORY_TYPE "auto"`, `FIFO_WRITE_DEPTH = DEPTH`,
`WRITE/READ_DATA_WIDTH = DATA_WIDTH`, `READ_MODE "fwft"`,
`FIFO_READ_LATENCY 0`, `CDC_SYNC_STAGES = CDC_STAGES`, `FULL_RESET_VALUE 1`,
`USE_ADV_FEATURES "0000"`. Writes are gated with `wr_rst_busy`, reads with
`rd_rst_busy`. No generated IP, no forced-Verilog dependency in our sources
(the XPM sim model is SystemVerilog, handled by Questa via `-L xpm`).

## 3. Block-design topology

None.

## 4. Verification strategy

- cocotb on Questa against the **real top** with the XPM model (default
  `tb/Makefile` configuration — the one gate 3 accepts).
- Fast loop: `make FAST=1` swaps in `sim_top` + behavioural `fifo_model`
  (no vendor libs). For quick iteration only.
- Tests: see `testplan.md` (order/integrity, backpressure on full, empty
  `tvalid` low, CDC in both clock ratios). UVM not required.

## 5. Simulation setup

- Compile order: `axis_fifo_ctrl.vhd`, `axis_fifo_loopback.vhd` (VHDL-2008).
- Vendor libs: `simlibs/questa` from `tools/compile_simlib.tcl` (`-L xpm`).
- Runner: `bash tools/run_tests.sh axis_fifo_loopback` → `sim/test_report.md`.
