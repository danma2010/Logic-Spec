---
status: approved
---

# axis_fifo_loopback — Design Plan

_Pre-approved as the reference example._

## 1. Module hierarchy

- `axis_fifo_loopback` — hardware top (Xilinx block-design wrapper)
  - `axis_fifo_ctrl` — custom VHDL, AXI-Stream ⇄ FIFO handshake glue
  - `fifo_512x64` — Xilinx FIFO Generator IP
- `sim_top` — simulation-only top (fast functional loop)
  - `axis_fifo_ctrl` — the **same** real RTL
  - `fifo_model` — behavioral FIFO stand-in

## 2. IP selection & configuration

Abstract "dual-clock FIFO 512×64, FWFT" → **Xilinx FIFO Generator**:
- Independent Clocks (Block RAM)
- Width 64, Depth 512
- First-Word-Fall-Through read mode

The custom logic has no forced-Verilog dependency; the IP's own sim model is
Verilog and is handled by Questa in the vendor-verification path.

## 3. Block-design topology (Xilinx, Tcl)

- Cells: `fifo_generator` (fifo_512x64) + module reference `axis_fifo_ctrl`.
- Connections: controller write side ↔ FIFO write port; read side ↔ FIFO read
  port; `wr_clk ← s_axis_aclk`, `rd_clk ← m_axis_aclk`.
- External: `s_axis_*`, `m_axis_*`, both clocks and resets.
- `validate_bd_design` → `make_wrapper` produces the hardware top.

## 4. Testbench strategy (cocotb on Questa)

- **Functional loop:** cocotb drives `s_axis` / reads `m_axis` against `sim_top`
  (real controller + behavioral FIFO), so the test runs with no IP setup.
- Covers every acceptance criterion: order/integrity, backpressure on full,
  `tvalid` low on empty, CDC with different clocks.
- **Full-vendor verification:** swap `sim_top`'s `fifo_model` for the generated
  `fifo_512x64` and reference the compiled libraries with `-L` (see
  `sim/RUN.md`). UVM not required.

## 5. Simulation setup

- Fast path: `make` (SIM=questa, TOPLEVEL_LANG=vhdl); sources =
  `axis_fifo_ctrl.vhd`, `fifo_model.vhd`, `sim_top.vhd`.
- Vendor path: run `build_ip.tcl`, `compile_simlib.tcl`, then `make` against the
  wrapper with `-L` libs.
- Results: `results.xml` (xUnit) + Questa `transcript`.
