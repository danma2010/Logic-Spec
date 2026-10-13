# The Verify Loop

Where a unit is checked against simulation, and why the loop pauses on every
real tool run.

## The manual boundary

The loop is **generate → simulate → repair**, and it is **human-gated**: the
agent prepares the design, the test plan, the testbench and the scripts;
**you** run Questa/Vivado; the per-test report comes back to the agent. The
agent never runs an EDA tool and never claims a run happened (rule 6 in
`CLAUDE.md`/`AGENTS.md`) — except in the opt-in auto mode below.

## "Check" has two halves

1. **Inside the simulation (your machine).** Each cocotb test (`tb/*.py`,
   written by `fpga-testbench` from one row of `testplan.md`) checks the
   design against that test's **pass criterion**. `tools/run_tests.sh` runs the
   tests one by one and `tools/make_report.py` turns the per-test results into
   `sim/test_report.md`: PASS/FAIL/ERROR/STALE per test, seed, log, AC
   coverage, and a verdict. *This is the design-vs-expected comparison.*
2. **Around the simulation (the agent).** `fpga-review` reads that report,
   takes failing tests in plan order, diagnoses each against its pass
   criterion (deep transcript/waveform reads go to `fpga-critic`), applies a
   minimal fix and prints the re-run command. When the verdict is PASS it
   applies gate 3. *This is the loop controller.*

## State diagram

```
                 ┌──────────────────────────────────────────────────────┐
   generate      ▼                                                       │ repair (minimal fix)
 ┌──────────────────────────────┐  you run              ┌────────────┐   │
 │ fpga-rtl    fpga-testbench    │  run_tests.sh <unit>  │  Questa    │   │
 │ fpga-ip     fpga-questa       │──────────────────────▶│ test by    │   │
 └──────────────────────────────┘                       │ test       │   │
      architecture.md: generated                         └─────┬──────┘   │
                                                               │ sim/tests/<ID>.xml|.log
                                                               ▼          │
                                                     sim/test_report.md   │
                                                               │          │
                                                               ▼          │
                                                       ┌──────────────┐   │
                                                       │ fpga-review  │───┘ FAIL / STALE
                                                       │ (+ critic)   │
                                                       └──────┬───────┘
                                                              │ verdict PASS (all must, default config)
                                                              ▼
                                            architecture.md: status = validated
```

## The exact commands

| Step | You run |
|---|---|
| Vendor libs (once per tool version) | `QUESTA_BIN=… vivado -mode batch -source tools/compile_simlib.tcl` |
| Lint the test plan | `python3 tools/make_report.py --check designs/<unit>` |
| All tests + report | `bash tools/run_tests.sh <unit>` |
| One test after a fix | `bash tools/run_tests.sh <unit> questa <ID>` |
| Reproduce a seed | `RANDOM_SEED=<n> bash tools/run_tests.sh <unit> questa <ID>` |
| Give the agent the result | point it at `designs/<unit>/sim/test_report.md` (or paste it) |
| SV/UVM path | `vsim -c -do designs/<unit>/sim/run_sim.tcl` |

The report marks a result **STALE** when RTL, testbench, IP Tcl or the test
plan changed after that test ran, so a fix always needs a re-run before gate 3.
Validation needs a **full** run in the **default** configuration (no
`MAKE_ARGS` such as `FAST=1`).

## Where each step lives

| Step | Locus |
|---|---|
| Plan the tests | `fpga-testplan` → `testplan.md` (gate 2) |
| Generate design + testbench | `fpga-rtl`, `fpga-ip`, `fpga-blockdesign`, `fpga-testbench` |
| Prepare sim scripts / instructions | `fpga-questa` |
| **Run the tests** | **you** (`tools/run_tests.sh`) |
| Check report, diagnose, fix, stamp | `fpga-review` (+ `fpga-critic`) |
| Record pass | `architecture.md` → `status: validated` |

## The loop recurs at every hierarchy level

- **leaf** — until the unit is `validated`.
- **composite** — again, as **integration tests** over the whole RTL subtree
  (sub-units already validated standalone).
- **top** — once more (top integration tests) before `fpga-toplevel` drives
  implementation to a bitstream.

## Why the boundary is safe

- **Never-claim-to-run** — the agent only prepares scripts and reads real results.
- **Validation gate** — `validated` only with a passing, current, full report;
  only a `validated` unit may be reused; changing it drops it to `generated`.

## Automatic mode (opt-in) — `fpga-auto`

When you explicitly invoke `fpga-auto <unit>`, the agent runs the loop itself:

```
        ┌────────────────────────────────────────────────────────┐
        ▼                                                         │ minimal fix (no port / test-plan change)
 ┌───────────────┐  run  ┌──────────────────┐ PASS ┌────────────────────┐
 │ generate/fix  │──────▶│ tools/run_tests  │─────▶│ tools/run_synth_   │──PASS─▶ done
 │  (agent)      │       │ → test_report.md │      │ check (OOC)        │
 └───────────────┘       └────────┬─────────┘      └─────────┬──────────┘
        ▲                         │ FAIL                     │ FAIL (RTL)
        └─────────────────────────┴──────────────────────────┘
                                (cap: 5 iterations)
                                         │ done
                                         ▼
                   summarize → ASK YOU TO CONFIRM → architecture.md: validated
```

Guardrails (`.claude/skills/fpga-auto/SKILL.md`): functional sim + OOC synth
only (never implementation, bitstream or hardware); gates 1 and 2 still apply;
bounded (default 5 iterations) with an audit trail in `sim/auto_log.md`; stops
on a repeated or ambiguous failure, a port/test-plan change, or a
timing/resource failure; asks before stamping `validated`; reports only real
results.
