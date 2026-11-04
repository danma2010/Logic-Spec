#!/usr/bin/env bash
# run_tests.sh <design> [SIM] [ID ...]
#
# The framework's standard test runner. <design> is a design folder (e.g. `.`).
# Lints the approved test plan (spec/testplan.md), runs each test (or the IDs
# given) in its own simulator invocation, in plan order, and builds
# <design>/sim/test_report.md (+ .json).
#
#   bash $LS/tools/run_tests.sh .                         # all tests, Questa
#   bash $LS/tools/run_tests.sh . questa T02 T05          # selected tests
#   RANDOM_SEED=123 bash $LS/tools/run_tests.sh . questa T01   # reproduce a seed
#   MAKE_ARGS="WAVES=1" bash $LS/tools/run_tests.sh .     # extra make vars
# ($LS = the Logic-Spec framework folder)
#
# A run with non-default MAKE_ARGS is recorded in the report; validation
# (gate 3) is only granted on the default testbench configuration.
# Exit: 0 gate met, 1 tests failing / gate not met, 2 setup error.
set -uo pipefail

DESIGN="${1:?usage: run_tests.sh <design_dir> [SIM] [ID ...]}"
SIM="${2:-questa}"
shift $(( $# >= 2 ? 2 : 1 ))
ONLY=("$@")
MAKE_ARGS="${MAKE_ARGS:-}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$DESIGN" ]      || { echo "SETUP ERROR: no design folder at ${DESIGN}"; exit 2; }
U="$(cd "$DESIGN" && pwd)"
UNIT="$(basename "$U")"
TB="${U}/tb"
TDIR="${U}/sim/tests"
REPORT="${ROOT}/tools/make_report.py"

[ -f "$U/spec/architecture.md" ] || { echo "SETUP ERROR: ${U}/spec/architecture.md not found (not a design folder?)"; exit 2; }
[ -f "$TB/Makefile" ] || { echo "SETUP ERROR: no ${U}/tb/Makefile (run fpga-testbench)"; exit 2; }
python3 "$REPORT" --check --require-approved "$U" || { echo "SETUP ERROR: test plan not runnable (see above)"; exit 2; }
mkdir -p "$TDIR"

# cocotb >= 2 filters with COCOTB_TEST_FILTER (regex); 1.x uses TESTCASE.
MAJOR="$(python3 -c 'import cocotb; print(cocotb.__version__.split(".")[0])' 2>/dev/null || echo 0)"
[ "$MAJOR" = "0" ] && { echo "SETUP ERROR: cocotb not importable by python3"; exit 2; }
[ -n "${RANDOM_SEED:-}" ] && export COCOTB_RANDOM_SEED="${COCOTB_RANDOM_SEED:-$RANDOM_SEED}"

echo "== run_tests: ${UNIT}  SIM=${SIM}  cocotb ${MAJOR}.x  ${MAKE_ARGS:+MAKE_ARGS=$MAKE_ARGS} =="
while read -r ID FN PRIO; do
  if [ ${#ONLY[@]} -gt 0 ] && [[ ! " ${ONLY[*]} " =~ " ${ID} " ]]; then continue; fi
  rm -f "$TB/results.xml" "$TDIR/${ID}.xml"
  if [ "$MAJOR" -ge 2 ]; then FILTER=(COCOTB_TEST_FILTER="^${FN}\$"); else FILTER=(TESTCASE="${FN}"); fi
  printf '  %-4s %-40s %-6s ... ' "$ID" "$FN" "$PRIO"
  # shellcheck disable=SC2086
  ( cd "$TB" && env "${FILTER[@]}" make SIM="$SIM" $MAKE_ARGS ) > "$TDIR/${ID}.log" 2>&1
  if [ -f "$TB/results.xml" ]; then
    mv -f "$TB/results.xml" "$TDIR/${ID}.xml"
    if grep -qE '<(failure|error)' "$TDIR/${ID}.xml"; then echo "FAIL"; else echo "done"; fi
  else
    echo "ERROR (no results.xml — see sim/tests/${ID}.log)"
  fi
done < <(python3 "$REPORT" --list "$U")

python3 "$REPORT" --report "$U" --sim "$SIM" --make-args "$MAKE_ARGS"
