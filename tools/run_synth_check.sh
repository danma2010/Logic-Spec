#!/usr/bin/env bash
# run_synth_check.sh <unit> [PART]
# Out-of-context synthesizability check: synth only, no I/O buffers, no P&R, no
# bitstream. Catches RTL that won't synthesize.
# TOP and PART come from designs/<unit>/architecture.md (`top:`, `part:`);
# a PART argument overrides. Needs designs/<unit>/build/synth_sources.tcl
# (run_sources.tcl format), which fpga-auto writes. Exit: 0 pass, 1 fail, 2 setup.
set -uo pipefail

UNIT="${1:?usage: run_synth_check.sh <unit> [PART]}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
U="${ROOT}/designs/${UNIT}"
BUILD="${U}/build"
ARCH="${U}/architecture.md"

fm() {  # read a scalar from architecture.md front-matter
  awk -v k="$1" 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f&&$0~"^"k":"{sub("^"k":[ \t]*","");sub(/[ \t]+#.*$/,"");print;exit}' "$ARCH"
}
[ -f "$ARCH" ] || { echo "SYNTH FAIL: missing designs/${UNIT}/architecture.md"; exit 2; }
TOP="$(fm top)"
PART="${2:-$(fm part)}"
[[ -n "$TOP"  && "$TOP"  != \<* ]] || { echo "SYNTH FAIL: architecture.md has no 'top:'";  exit 2; }
[[ -n "$PART" && "$PART" != \<* ]] || { echo "SYNTH FAIL: architecture.md has no 'part:'"; exit 2; }
[ -f "${BUILD}/synth_sources.tcl" ] || {
  echo "SYNTH FAIL: missing designs/${UNIT}/build/synth_sources.tcl (fpga-auto writes it)"; exit 2; }

echo "== synth check (OOC): ${UNIT}  TOP=${TOP}  PART=${PART} =="
( cd "$BUILD" && vivado -mode batch -notrace -nojournal \
    -source "${ROOT}/templates/vivado/synth_check.tcl" \
    -tclargs "$TOP" "$PART" "${BUILD}/synth_sources.tcl" ) 2>&1 | tee "${BUILD}/synth.log"

if grep -qE '^ERROR:' "${BUILD}/synth.log"; then
  echo "SYNTH FAIL: errors (see build/synth.log)"; exit 1
fi
if grep -q 'CRITICAL WARNING' "${BUILD}/synth.log"; then
  echo "SYNTH FAIL: critical warnings (see build/synth.log)"; exit 1
fi
if grep -q 'SYNTH_CHECK_DONE' "${BUILD}/synth.log"; then
  echo "SYNTH PASS: ${UNIT}"; exit 0
fi
echo "SYNTH FAIL: synthesis did not complete"; exit 1
