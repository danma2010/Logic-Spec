# The Verify Loop

Where the design gets checked against simulation — and why the loop pauses on
every real tool run.

## The manual boundary

The loop is **generate → simulate → repair**, and it is **human-gated**: Claude
prepares the design and the scripts, **you** run Questa/Vivado, and the results
come back to Claude. Claude never runs an EDA tool and never claims a run
happened (enforced by `CLAUDE.md`). The loop therefore *pauses* at every real
simulation — by design, because EDA execution is manual here.

## "Check" has two halves

1. **Inside the simulation (your machine).** The **cocotb testbench** (`tb/*.py`,
   written by `/fpga-testbench` from the spec's GIVEN/WHEN/THEN criteria) is what
   actually checks the design's behaviour against expectation. It runs inside
   Questa; the verdict lands in `results.xml` (xUnit) + the `transcript`. *This is
   the design-vs-expected comparison.*
2. **Around the simulation (Claude).** `/fpga-review` reads that verdict, checks
   the design against the **simulation result**, correlates failures to `plan.md`
   and the acceptance criteria (delegating deep transcript/waveform reads to the
   `fpga-critic` subagent), applies a minimal fix, and prints the re-run command.
   *This is the loop controller.*

## State diagram

```
                 ┌────────────────────────────────────────────────┐
   generate      ▼                                                 │ repair (minimal fix)
 ┌───────────────────────────┐   you run     ┌──────────────┐      │
 │ /fpga-rtl  /fpga-testbench │──────────────▶│   Questa      │     │
 │ /fpga-ip   /fpga-questa    │  make / vsim  │  (your PC)    │     │
 └───────────────────────────┘               └──────┬───────┘      │
        unit.md: generated                          │ results.xml   │
                                                     │ transcript    │
                                            paste    ▼               │
                                              ┌──────────────┐       │
                                     ────────▶│ /fpga-review │───────┘
                                              │  (+ critic)  │   FAIL
                                              └──────┬───────┘
                                                     │ PASS
                                                     ▼
                                        unit.md: status = validated
```

## The exact commands

| Step | You run |
|---|---|
| Fast functional loop | `cd designs/<unit>/tb && make` |
| Vendor-model path | see `designs/<unit>/sim/RUN.md` (`compile_simlib` → `build_ip` → `build_bd` → `make`) |
| Paste back | copy `results.xml` (and/or `transcript`) into the chat for `/fpga-review` |
| Re-run after a fix | re-run the same `make` (or `vsim -c -do sim/run_sim.tcl` for the UVM path) |

Claude closes nothing on its own — after each fix it hands you the command and
waits for the next paste.

## Where each step lives

| Step | Locus |
|---|---|
| Generate design + testbench | `/fpga-rtl`, `/fpga-ip`, `/fpga-blockdesign`, `/fpga-testbench` |
| Prepare sim scripts | `/fpga-questa` |
| **Run the sim** | **you** (Questa) |
| Check result, diagnose, fix, stamp | `/fpga-review` (+ `fpga-critic`) |
| Record pass | `unit.md` → `status: validated` |

## The loop recurs at every hierarchy level

Same `/fpga-review` locus each time — only the DUT scope grows:

- **leaf** — run the loop until the unit is `validated`.
- **composite** — run it again as an **integration test** over the whole RTL
  subtree (sub-units already validated standalone).
- **top** — run it once more (top integration sim) before `/fpga-toplevel`
  drives implementation to a bitstream.

## Why the boundary is safe

- **Never-claim-to-run** — Claude only prepares scripts and reads pasted results.
- **Validation gate** — a unit is stamped `validated` only with a passing result
  in hand, and only a `validated` unit may be reused.
