#!/usr/bin/env bash
# run_synth_check.sh <unit> [PART]
# Out-of-context synthesizability check: synth only, no I/O buffers, no P&R, no
# bitstream. Catches RTL that won't synthesize. Needs build/synth_sources.tcl,
# which /fpga-auto generates (bottom-up read_vhdl + read_ip). Exit: 0/1/2.
set -uo pipefail

UNIT="${1:?usage: run_synth_check.sh <unit> [PART]}"
PART="${2:-xc7a35ticsg324-1L}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${ROOT}/designs/${UNIT}/build"

[ -f "${BUILD}/synth_sources.tcl" ] || {
  echo "SYNTH FAIL: missing designs/${UNIT}/build/synth_sources.tcl (run /fpga-auto to generate)"; exit 2; }

echo "== synth check (OOC): ${UNIT} (PART=${PART}) =="
( cd "$BUILD" && vivado -mode batch -notrace \
    -source "${ROOT}/templates/vivado/synth_check.tcl" \
    -tclargs "$UNIT" "$PART" ) 2>&1 | tee "${BUILD}/synth.log"

if grep -qE '^ERROR:|CRITICAL WARNING' "${BUILD}/synth.log"; then
  echo "SYNTH FAIL: errors/critical warnings (see build/synth.log)"; exit 1
fi
if grep -q 'SYNTH_CHECK_DONE' "${BUILD}/synth.log"; then
  echo "SYNTH PASS: ${UNIT}"; exit 0
fi
echo "SYNTH FAIL: synthesis did not complete"; exit 1
