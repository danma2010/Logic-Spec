---
name: ddc_channelizer
vendor: xilinx
kind: composite
status: planned            # spec only; no plan approved, no code yet
dependencies:
  - axis_fifo_loopback     # output CDC/rate buffer — must be VALIDATED before plan approval
ports:
  - { name: s_axis_aclk,    dir: in,  width: 1 }
  - { name: s_axis_aresetn, dir: in,  width: 1 }
  - { name: s_axis_tdata,   dir: in,  width: 32 }   # packed I/Q, 2*IN_WIDTH
  - { name: s_axis_tvalid,  dir: in,  width: 1 }
  - { name: s_axis_tready,  dir: out, width: 1 }
  - { name: m_axis_aclk,    dir: in,  width: 1 }
  - { name: m_axis_aresetn, dir: in,  width: 1 }
  - { name: m_axis_tdata,   dir: out, width: 32 }   # packed I/Q, 2*OUT_WIDTH
  - { name: m_axis_tvalid,  dir: out, width: 1 }
  - { name: m_axis_tready,  dir: in,  width: 1 }
  - { name: s_axi_aclk,     dir: in,  width: 1 }
  - { name: s_axi_aresetn,  dir: in,  width: 1 }
  # + AXI4-Lite AW/W/B/AR/R channels (control register file)
validated: {}
---

# ddc_channelizer — Unit manifest

Complex composite: a DDC/channelizer datapath built from Xilinx DSP IP
(DDS, complex multiplier, CIC, FIR, clocking) plus the reused `axis_fifo_loopback`
for the output clock-domain crossing. `kind: composite` because it instantiates a
validated sub-unit; `status: planned` because only the spec exists so far — next
step is `/fpga-plan`.
