---
name: axis_fifo_loopback
vendor: xilinx
kind: leaf
status: generated          # plan approved + code generated; not yet validated (sim not run)
dependencies: []
ports:
  - { name: s_axis_aclk,    dir: in,  width: 1 }
  - { name: s_axis_aresetn, dir: in,  width: 1 }
  - { name: s_axis_tdata,   dir: in,  width: 64 }
  - { name: s_axis_tvalid,  dir: in,  width: 1 }
  - { name: s_axis_tready,  dir: out, width: 1 }
  - { name: m_axis_aclk,    dir: in,  width: 1 }
  - { name: m_axis_aresetn, dir: in,  width: 1 }
  - { name: m_axis_tdata,   dir: out, width: 64 }
  - { name: m_axis_tvalid,  dir: out, width: 1 }
  - { name: m_axis_tready,  dir: in,  width: 1 }
validated: {}
---

# axis_fifo_loopback — Unit manifest

Clock-domain-crossing AXI-Stream loopback (dual-clock FWFT FIFO). `status`
becomes `validated` once `cd tb && make` passes and `/fpga-review` records it —
only then may a higher unit instantiate it.
