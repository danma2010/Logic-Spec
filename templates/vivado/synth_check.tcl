# synth_check.tcl — out-of-context synthesizability check for one unit.
# Invoked by tools/run_synth_check.sh:
#   vivado -mode batch -source templates/vivado/synth_check.tcl \
#          -tclargs <TOP> <PART> <path/to/synth_sources.tcl>
# synth_sources.tcl is written by fpga-auto in designs/<unit>/build/ using the
# run_sources.tcl format (paths relative to its own location).

set TOP     [lindex $argv 0]
set PART    [lindex $argv 1]
set SOURCES [file normalize [lindex $argv 2]]
set OUTDIR  [file dirname $SOURCES]

create_project -in_memory -part $PART
source $SOURCES

# OOC: no I/O buffer insertion, no pin constraints needed — pure synthesizability.
synth_design -top $TOP -part $PART -mode out_of_context

report_utilization -file $OUTDIR/synth_util.rpt
puts "SYNTH_CHECK_DONE $TOP"
