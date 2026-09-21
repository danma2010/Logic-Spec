# axis_fifo_loopback — Spec

Summary: Clock-domain-crossing AXI-Stream loopback. 64-bit words written on the
`s_axis` clock are buffered by a dual-clock FIFO and read out in order on the
`m_axis` clock.

Vendor: xilinx
Vendor rationale: Target is a 7-series/UltraScale part; the FIFO Generator
provides a mature independent-clocks BRAM FIFO with first-word-fall-through,
which matches the CDC buffering need directly.

Interfaces:
- s_axis (slave):  s_axis_aclk, s_axis_aresetn, s_axis_tdata[63:0], s_axis_tvalid, s_axis_tready
- m_axis (master): m_axis_aclk, m_axis_aresetn, m_axis_tdata[63:0], m_axis_tvalid, m_axis_tready

Abstract IP:
- dual-clock FIFO 512x64, first-word-fall-through

Acceptance criteria:
- GIVEN a stream of N words on s_axis WHEN they are read out on m_axis THEN every
  word appears exactly once, in order (no loss, duplication, or reordering).
- GIVEN the FIFO is full WHEN s_axis_tvalid is asserted THEN s_axis_tready is
  deasserted (backpressure).
- GIVEN the FIFO is empty THEN m_axis_tvalid is deasserted.
- GIVEN s_axis and m_axis run at different clock frequencies THEN data integrity
  is preserved across the clock-domain crossing.
