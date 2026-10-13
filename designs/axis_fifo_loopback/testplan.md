---
unit: axis_fifo_loopback
status: pending           # pending | approved — any edit resets to pending
---

# axis_fifo_loopback — Test plan

Derived from `architecture.md` AC-1…AC-4. One cocotb test per row in
`tb/test_axis_fifo_loopback.py`. Clocks: `s_axis_aclk`/`m_axis_aclk` periods as
stated per test.

## Features
- **F1** Data path: ordered, lossless, duplicate-free transfer.
- **F2** Write-side backpressure when full.
- **F3** Read-side `tvalid` behaviour when empty.
- **F4** Clock-domain crossing in both frequency ratios.

## Tests

| ID | Function | Features | AC | Priority | Pass criterion |
|---|---|---|---|---|---|
| T01 | t01_order_integrity | F1, F4 | AC-1, AC-4 | must | 1024 random words, s 10 ns / m 7 ns, consumer stalls 20 % at random: received list == sent list (count, order, bit-exact) |
| T02 | t02_backpressure_full | F2, F1 | AC-2, AC-1 | must | consumer stalled; producer offers words continuously: `s_axis_tready` goes low after N accepted words with DEPTH-8 ≤ N ≤ DEPTH+4, stays low for 50 s-clk cycles while tvalid=1 with no beat accepted; after releasing the consumer all N words are received in order |
| T03 | t03_empty_tvalid_low | F3 | AC-3 | must | after reset with no input, `m_axis_tvalid` = 0 on every m-clk edge for 200 cycles; after a 16-word burst is fully drained, `m_axis_tvalid` = 0 for the next 100 cycles |
| T04 | t04_cdc_fast_writer | F4, F1, F2 | AC-4, AC-1, AC-2 | must | s 4 ns / m 13 ns (writer ~3× faster), 2048 random words, consumer stalls 20 %: received == sent; `s_axis_tready` observed low at least once (FIFO filled) |

## Waivers
- (none)
