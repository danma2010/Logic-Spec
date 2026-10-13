#==============================================================================
# Vivado non-project build — modular. Generated/edited by fpga-toplevel.
# Emitted to designs/<top>/impl/build.tcl.   Part : <PART>   Top : <TOP>
# Keep this file stable; put file lists in run_sources.tcl / run_constraints.tcl.
# RUN MANUALLY (from any directory):
#   vivado -mode batch -source designs/<top>/impl/build.tcl
#==============================================================================

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set TOP    "<TOP>"                ;# = architecture.md `top:`
set PART   "<PART>"               ;# = architecture.md `part:`
set OUTDIR $SCRIPT_DIR/out
file mkdir $OUTDIR
create_project -in_memory -part $PART

# 1. Sources: RTL hierarchy (bottom-up) + IP  ---------------------------------
source $SCRIPT_DIR/run_sources.tcl

# 2. Constraints: pins + timing  ---------------------------------------------
source $SCRIPT_DIR/run_constraints.tcl

# 3. Synthesis  ---------------------------------------------------------------
synth_design -top $TOP -part $PART
write_checkpoint -force $OUTDIR/post_synth.dcp
report_utilization    -file $OUTDIR/post_synth_util.rpt
report_timing_summary -file $OUTDIR/post_synth_timing.rpt

# 4. Implementation  ----------------------------------------------------------
opt_design
place_design
write_checkpoint -force $OUTDIR/post_place.dcp
phys_opt_design
route_design
write_checkpoint -force $OUTDIR/post_route.dcp

# 5. Reports  -----------------------------------------------------------------
report_timing_summary -file $OUTDIR/timing.rpt
report_utilization    -file $OUTDIR/util.rpt
report_power          -file $OUTDIR/power.rpt
report_drc            -file $OUTDIR/drc.rpt

# 6. Output  ------------------------------------------------------------------
# Versal parts: replace the next line with  write_device_image
write_bitstream -force $OUTDIR/${TOP}.bit
puts "===== Build complete: $OUTDIR/${TOP}.bit ====="
