# build_ip.tcl — generate & configure vendor IP for one unit (Vivado batch).
# Emitted to designs/<unit>/tcl/build_ip.tcl by fpga-ip from the approved plan.
#
# RUN MANUALLY (from any directory):
#   vivado -mode batch -source designs/<unit>/tcl/build_ip.tcl
#
# Output: designs/<unit>/tcl/ip/<module>/<module>.xci (+ generated targets),
# which run_sources.tcl / synth_sources.tcl read with read_ip.

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set PART    "<PART>"              ;# = architecture.md `part:`
set IP_DIR  $SCRIPT_DIR/ip
file mkdir $IP_DIR
create_project -in_memory -part $PART

# --- Example: abstract "dual-clock FIFO 512x64, FWFT" -> FIFO Generator -------
create_ip -name fifo_generator -vendor xilinx.com -library ip \
          -module_name fifo_512x64 -dir $IP_DIR -force
set_property -dict [list \
    CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width    {64} \
    CONFIG.Input_Depth         {512} \
] [get_ips fifo_512x64]
generate_target all [get_ips fifo_512x64]
# synth_ip [get_ips fifo_512x64]   ;# optional: pre-synthesize OOC
# ---------------------------------------------------------------------------

puts "IP generation complete: $IP_DIR"
