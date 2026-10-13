# compile_simlib.tcl — compile vendor simulation libraries for Questa (ONE-TIME,
# per Vivado/Questa version). Shared by every unit.
#
# RUN MANUALLY (from any directory):
#   QUESTA_BIN=<path to questa bin dir> vivado -mode batch -source tools/compile_simlib.tcl
#   optional: FAMILY=artix7 (default: all — slow)   SIMLIB_DIR=<override output dir>
#
# Output: <repo>/simlibs/questa/ (+ modelsim.ini with all library mappings).
# tb/Makefile and sim/run_sim.tcl pick it up automatically.
# (Altera/Intel: use Quartus' simulation-library compiler instead.)

set REPO [file normalize [file dirname [info script]]/..]
set LIB_DIR [expr {[info exists ::env(SIMLIB_DIR)] ? $::env(SIMLIB_DIR) : "$REPO/simlibs/questa"}]
set FAMILY  [expr {[info exists ::env(FAMILY)]     ? $::env(FAMILY)     : "all"}]
if {![info exists ::env(QUESTA_BIN)]} {
    error "Set QUESTA_BIN to the Questa bin directory (the one containing vsim)."
}
file mkdir $LIB_DIR

compile_simlib -simulator questa \
               -simulator_exec_path $::env(QUESTA_BIN) \
               -directory $LIB_DIR \
               -family    $FAMILY \
               -language  all \
               -library   all

puts "Sim libraries compiled to $LIB_DIR (mappings in $LIB_DIR/modelsim.ini)"
