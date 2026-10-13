#!/usr/bin/env bash
# run_sim.sh <unit> [SIM]
# Single-run SMOKE check: all cocotb tests in one simulator run, one-line verdict.
# Not used for validation — the standard runner is tools/run_tests.sh (test by
# test + sim/test_report.md). Simulator-agnostic via cocotb's SIM
# (questa|icarus|verilator|ghdl|...). Exit: 0 pass, 1 fail, 2 setup error.
set -uo pipefail

UNIT="${1:?usage: run_sim.sh <unit> [SIM]}"
SIM="${2:-questa}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TB="${ROOT}/designs/${UNIT}/tb"
SIMDIR="${ROOT}/designs/${UNIT}/sim"
mkdir -p "$SIMDIR"

[ -d "$TB" ] || { echo "SIM FAIL: no tb dir at designs/${UNIT}/tb"; exit 2; }
RES="${TB}/results.xml"
rm -f "$RES"                       # never read a previous run's verdict

echo "== smoke sim: ${UNIT} (SIM=${SIM}) =="
( cd "$TB" && make SIM="$SIM" ) 2>&1 | tee "${SIMDIR}/last_sim.log"

[ -f "$RES" ] || { echo "SIM FAIL: no results.xml produced (compile/elab error — see sim/last_sim.log)"; exit 2; }

python3 - "$RES" <<'PY'
import sys, xml.etree.ElementTree as ET
r = ET.parse(sys.argv[1]).getroot()
tests = len(r.findall('.//testcase'))
bad   = len(r.findall('.//failure')) + len(r.findall('.//error'))
print(f"SIM {'PASS' if bad == 0 else 'FAIL'}: {tests} tests, {bad} failing")
sys.exit(0 if bad == 0 else 1)
PY
