# axis_fifo_loopback — Requirements (input)

> Input document. The framework never modifies this file; `fpga-architect`
> derives `architecture.md` from it.
> (Migrated 2026-10-12: the former manifest/architecture content moved to
> `architecture.md`; the requirements below are unchanged.)

## Purpose
A clock-domain-crossing AXI-Stream loopback: words written on the `s_axis`
clock are buffered and read out, in order, on the `m_axis` clock. Intended as a
reusable CDC/rate buffer for higher units.

## Interfaces
- `s_axis` (slave): `s_axis_aclk`, `s_axis_aresetn`, `s_axis_tdata`,
  `s_axis_tvalid`, `s_axis_tready`.
- `m_axis` (master): `m_axis_aclk`, `m_axis_aresetn`, `m_axis_tdata`,
  `m_axis_tvalid`, `m_axis_tready`.
- Data width 64 bits by default; must be adjustable when the unit is reused.

## Functional requirements
- Every word written appears exactly once on `m_axis`, in order — no loss,
  duplication or reordering.
- When the buffer is full, `s_axis_tready` is deasserted (backpressure).
- When the buffer is empty, `m_axis_tvalid` is deasserted.
- Integrity is preserved when the two clocks run at different frequencies.

## Performance & resources
Buffer depth 512 words; one word per clock on each side when not blocked.

## Target
Xilinx 7-series/UltraScale (Artix-7 `xc7a35ticsg324-1L` for the example).

## Verification expectations
Random data, random consumer stalls, both "write faster" and "read faster"
clock ratios, a deliberate full condition.
