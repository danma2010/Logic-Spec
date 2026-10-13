# Running axis_fifo_loopback

All commands from the repo root. Results: `sim/test_report.md` (per test,
PASS/FAIL, seed, log in `sim/tests/<ID>.log`). Bring it to `fpga-review`.

## 0. One-time: vendor simulation libraries (shared by all units)

```
QUESTA_BIN=<questa>/bin FAMILY=artix7 vivado -mode batch -source tools/compile_simlib.tcl
```
Produces `simlibs/questa/` (incl. `xpm`). First use: check that
`simlibs/questa/modelsim.ini` maps `xpm` to an absolute path.

## 1. Lint the test plan (no EDA)

```
python3 tools/make_report.py --check designs/axis_fifo_loopback
```

## 2. Run the tests — default configuration (counts for validation)

```
bash tools/run_tests.sh axis_fifo_loopback                  # all, one by one
bash tools/run_tests.sh axis_fifo_loopback questa T02       # one test
RANDOM_SEED=<n> bash tools/run_tests.sh axis_fifo_loopback questa T02   # reproduce
```

DUT = `axis_fifo_loopback` (real top, `xpm_fifo_async` via `-L xpm`).

## 3. Fast loop (no vendor libs — iteration only, never for validation)

```
MAKE_ARGS="FAST=1" bash tools/run_tests.sh axis_fifo_loopback
# or: cd designs/axis_fifo_loopback/tb && make FAST=1
```

DUT = `sim_top` (same `axis_fifo_ctrl` + behavioural `fifo_model`). The report
records `make args: FAST=1`, and `fpga-review` will not validate from it.
