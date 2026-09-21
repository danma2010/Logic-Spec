# ddc_channelizer — Spec

> **Skeleton for a complex, multi-IP unit.** Copy and adapt. Values in
> `<angle brackets>` are per-design; the section structure and the IP roster are
> what the architect stage should always produce for a unit like this.

Summary: A digital down-converter / single-channel channelizer. It mixes a
real/complex input stream down to baseband with a programmable NCO, decimates by
`<R>`, applies a channel-select FIR, and streams complex baseband out — with an
AXI-Lite control interface for tuning, gain, and coefficients.

Vendor: xilinx
Vendor rationale: The datapath is a classic AMD DSP-IP chain (DDS Compiler,
Complex Multiplier, CIC, FIR Compiler) with hardened DSP48 mapping; the ecosystem
and sim models are mature. Target part `<xc… part>`.

## Parameters (generics)

| Generic | Meaning | Example |
|---|---|---|
| `IN_WIDTH` | input sample width (per I/Q) | 16 |
| `OUT_WIDTH` | output sample width (per I/Q) | 16 |
| `NCO_WIDTH` | NCO phase/freq width | 32 |
| `CIC_DECIM` | CIC decimation factor | `<R_cic>` |
| `FIR_DECIM` | FIR decimation factor | `<R_fir>` |
| `TOTAL_DECIM` | `CIC_DECIM * FIR_DECIM` | `<R>` |

## Interfaces

- **s_axis (input samples, sample-clock domain):** `s_axis_aclk`,
  `s_axis_aresetn`, `s_axis_tdata[<2*IN_WIDTH-1>:0]` (packed I/Q or real),
  `s_axis_tvalid`, `s_axis_tready`.
- **m_axis (baseband out, output-clock domain):** `m_axis_aclk`,
  `m_axis_aresetn`, `m_axis_tdata[<2*OUT_WIDTH-1>:0]` (packed I/Q),
  `m_axis_tvalid`, `m_axis_tready`.
- **s_axi_lite (control):** standard AXI4-Lite (`s_axi_aclk`, `s_axi_aresetn`,
  AW/W/B/AR/R channels) — registers: NCO frequency word, gain, FIR coeff reload,
  status.

## Clocking & reset domains

- `sample_clk` — full-rate input domain (mixer + CIC).
- `proc_clk` — decimated processing domain (FIR + control), from Clocking Wizard.
- `out_clk` — output/consumer domain.
- CDC from `proc_clk` → `out_clk` is handled by the reused output FIFO unit
  (see Dependencies). Resets are per-domain, async-assert/sync-deassert.

## Internal datapath (hierarchy sketch)

```
s_axis ─► [Complex Multiplier] ─► [CIC Compiler] ─► [FIR Compiler] ─► gain ─► [axis_fifo_loopback] ─► m_axis
              ▲  (mixer)             (decimate R_cic)   (decimate R_fir)  (DSP48)   (CDC + rate buffer)
              │
        [DDS Compiler] (NCO)  ◄── AXI-Lite freq word
        [Clocking Wizard] ─► proc_clk
        [AXI-Lite reg file] (custom RTL) ─► freq / gain / coeff reload / status
```

## Xilinx IP cores

| IP core | Role | Key config (abstract) | Instance |
|---|---|---|---|
| Clocking Wizard | derive `proc_clk` | in `<f_sample>`, out `<f_proc>` | `clk_wiz_0` |
| DDS Compiler | NCO / digital LO | phase width `NCO_WIDTH`, SFDR `<dBc>`, programmable phase-increment via AXI-Stream config | `dds_0` |
| Complex Multiplier | I/Q mixer | `IN_WIDTH`, full-precision then round | `cmpy_0` |
| CIC Compiler | high-ratio decimation | decim `CIC_DECIM`, stages `<N>`, diff delay `<M>` | `cic_0` |
| FIR Compiler | channel / CIC-comp filter | decim `FIR_DECIM`, coeffs `<tap set>`, reloadable | `fir_0` |
| Floating-Point / DSP48 (optional) | AGC / gain scaling | fixed-point gain | `gain_0` |

## Dependencies (reused validated units — direct RTL instantiation)

- `axis_fifo_loopback` — output CDC + rate-adaptation buffer (`proc_clk` →
  `out_clk`). **Must be `status: validated`** before this unit's plan is
  approved. (Widen its `DATA_WIDTH` generic to `2*OUT_WIDTH` when instantiating.)

## Abstract IP (for architect resolution)

- clocking: 1× PLL/MMCM (`<f_sample>` → `<f_proc>`)
- NCO: programmable DDS, `NCO_WIDTH`-bit
- complex mixer
- decimating CIC, ratio `CIC_DECIM`
- decimating, reloadable FIR, ratio `FIR_DECIM`
- dual-clock AXI-Stream FIFO (satisfied by reused `axis_fifo_loopback`)

## Acceptance criteria (GIVEN / WHEN / THEN)

- GIVEN a CW tone at input frequency `<f_in>` WHEN the NCO is tuned to `<f_in>`
  THEN the output baseband tone sits within `<±Δf>` of DC.
- GIVEN a full-rate input stream WHEN decimation `TOTAL_DECIM` is applied THEN the
  output sample rate equals input_rate / `TOTAL_DECIM` and no samples are dropped
  (AXI-Stream backpressure honored end to end).
- GIVEN an out-of-band interferer in the FIR stopband THEN it is attenuated by
  `≥ <stopband_dB>` dB relative to the passband.
- GIVEN an AXI-Lite write to the NCO frequency register THEN the LO retunes within
  `<N_retune>` proc-clock cycles and status reflects "locked".
- GIVEN the output crosses `proc_clk → out_clk` THEN data integrity and order are
  preserved (already validated at the `axis_fifo_loopback` sub-unit level).

## Performance & resource targets

| Metric | Target |
|---|---|
| Throughput | `≥ <Msps>` at the input |
| Latency (in→out) | `≤ <cycles>` |
| fmax (`sample_clk`) | `≥ <MHz>` |
| DSP48 budget | `≤ <n>` (mixer + CIC + FIR) |
| BRAM budget | `≤ <n>` (coeff RAM + FIFO) |

## Verification notes (for fpga-testbench / fpga-plan)

- Integration test in cocotb: generate a synthetic complex tone + interferer
  (numpy), drive `s_axis`, collect `m_axis`, and compare against a **Python golden
  DDC model** (mix → decimate → filter). Assert on tone location, passband gain,
  and stopband attenuation (an SNR/error metric, not bit-exact, given IP rounding).
- Fast functional loop: numeric/behavioral stand-ins for each IP stage (the
  `fifo_model` pattern) so the test runs without vendor libs.
- Vendor verification: real IP sim models via `compile_simlib` + `-L`.

## Open items (TBD)

- `<R_cic>` / `<R_fir>` split and CIC compensation taps.
- NCO SFDR vs. DSP48 budget trade.
- Whether AGC is required (gain_0) or fixed gain suffices.
