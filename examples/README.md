# Examples

Each folder is a complete Logic-Spec **design project** (one design = one
folder), kept inside the framework only as reference. Your own designs live
anywhere outside the framework tree. Layout: documents in `spec/`, code beside
it (`rtl/`, `tb/`, `sim/`, …) — see the framework README.

- `axis_fifo_loopback` — leaf: AXI-Stream CDC FIFO (`axis_fifo_ctrl` +
  `xpm_fifo_async`), tests T01–T04. Status `generated`; gate 0 (spec work),
  plan and test plan awaiting approval.
- `ddc_channelizer` — composite skeleton reusing `../axis_fifo_loopback`;
  `planned`, blocked at gate 1 until its dependency is validated.
