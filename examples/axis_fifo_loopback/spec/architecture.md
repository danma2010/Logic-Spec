---
name: axis_fifo_loopback
vendor: xilinx
part: xc7a35ticsg324-1L
kind: leaf
top: axis_fifo_loopback
status: generated          # RTL generated; not validated (tests not run)
dependencies: []
ports:
  - { name: s_axis_aclk,    dir: in,  width: 1 }
  - { name: s_axis_aresetn, dir: in,  width: 1 }
  - { name: s_axis_tdata,   dir: in,  width: DATA_WIDTH }
  - { name: s_axis_tvalid,  dir: in,  width: 1 }
  - { name: s_axis_tready,  dir: out, width: 1 }
  - { name: m_axis_aclk,    dir: in,  width: 1 }
  - { name: m_axis_aresetn, dir: in,  width: 1 }
  - { name: m_axis_tdata,   dir: out, width: DATA_WIDTH }
  - { name: m_axis_tvalid,  dir: out, width: 1 }
  - { name: m_axis_tready,  dir: in,  width: 1 }
validated: {}
---

# axis_fifo_loopback — Architecture

Derived from `spec.md`. Clock-domain-crossing AXI-Stream loopback: words written
on the `s_axis` clock are buffered by a dual-clock FWFT FIFO and read out in
order on the `m_axis` clock.

## Vendor & part rationale
Xilinx, Artix-7 `xc7a35ticsg324-1L` (example part). The FIFO is resolved to
the **XPM `xpm_fifo_async`** macro: parameterizable from VHDL generics (so a
parent can set `DATA_WIDTH`), no IP-generation step, BRAM-mapped,
first-word-fall-through.

## Generics
| Generic | Meaning | Default |
|---|---|---|
| `DATA_WIDTH` | `tdata` width | 64 |
| `DEPTH` | FIFO depth (power of 2, ≥ 16) | 512 |
| `CDC_STAGES` | synchronizer stages | 2 |

## Interfaces
- `s_axis` (slave, `s_axis_aclk`): `tdata[DATA_WIDTH-1:0]`, `tvalid`, `tready`.
- `m_axis` (master, `m_axis_aclk`): `tdata[DATA_WIDTH-1:0]`, `tvalid`, `tready`.
- Reset: `s_axis_aresetn` (active low) resets the FIFO (XPM resets both
  domains from the write-domain reset). `m_axis_aresetn` is kept for AXI-Stream
  convention; reads are blocked while the XPM reports `rd_rst_busy`.

## Hierarchy
- `axis_fifo_loopback` (`rtl/axis_fifo_loopback.vhd`) — unit top
  - `axis_fifo_ctrl` (`rtl/axis_fifo_ctrl.vhd`) — AXI-Stream ⇄ FIFO handshake glue
  - `xpm_fifo_async` — Xilinx XPM macro (library `xpm`)
- Test-only fast loop: `tb/sim_top.vhd` = `axis_fifo_ctrl` + behavioural
  `tb/fifo_model.vhd` (`make FAST=1`; never used for validation).

## Dependencies
- none

## Abstract IP
- dual-clock FIFO 512×`DATA_WIDTH`, first-word-fall-through → `xpm_fifo_async`

## Acceptance criteria
- **AC-1** GIVEN a stream of N words on `s_axis` WHEN they are read out on
  `m_axis` THEN every word appears exactly once, in order (no loss,
  duplication or reordering).
- **AC-2** GIVEN the FIFO is full WHEN `s_axis_tvalid` is asserted THEN
  `s_axis_tready` is deasserted and no beat is accepted until space frees.
- **AC-3** GIVEN the FIFO is empty THEN `m_axis_tvalid` is deasserted.
- **AC-4** GIVEN `s_axis` and `m_axis` run at different clock frequencies
  (either one faster) THEN data integrity and order are preserved.
