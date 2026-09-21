#==============================================================================
# Vivado non-project build — modular. Generated/edited by fpga-toplevel.
# Part : <PART>          Top : <TOP>
# Keep this file stable; put file lists in run_sources.tcl / run_constraints.tcl.
# RUN MANUALLY:  vivado -mode batch -source build.tcl
#==============================================================================

set TOP    "<TOP>"
set PART   "<PART>"
set OUTDIR "./out"
file mkdir $OUTDIR
set_part $PART

# 1. Sources: RTL hierarchy (bottom-up) + IP  ---------------------------------
source run_sources.tcl
report_compile_order -missing_instances

# 2. Constraints: pins + timing  ---------------------------------------------
source run_constraints.tcl

# 3. Synthesis  ---------------------------------------------------------------
synth_design -top $TOP -part $PART
write_checkpoint -force ${OUTDIR}/post_synth.dcp
report_utilization    -file ${OUTDIR}/post_synth_util.rpt
report_timing_summary -file ${OUTDIR}/post_synth_timing.rpt

# 4. Implementation  ----------------------------------------------------------
opt_design
place_design
write_checkpoint -force ${OUTDIR}/post_place.dcp
phys_opt_design
route_design
write_checkpoint -force ${OUTDIR}/post_route.dcp

# 5. Reports  -----------------------------------------------------------------
report_timing_summary -file ${OUTDIR}/timing.rpt
report_utilization    -file ${OUTDIR}/util.rpt
report_power          -file ${OUTDIR}/power.rpt
report_drc            -file ${OUTDIR}/drc.rpt

# 6. Output  ------------------------------------------------------------------
# Versal parts: replace the next line with  write_device_image
write_bitstream -force ${OUTDIR}/${TOP}.bit
puts "===== Build complete: ${OUTDIR}/${TOP}.bit ====="
