# build_ip.tcl — generate & configure Xilinx IP (non-project / batch mode)
#
# RUN MANUALLY:
#   vivado -mode batch -source build_ip.tcl
#
# The fpga-ip skill fills this in per design from the approved plan. The block
# below is an example that resolves the abstract IP "dual-clock FIFO 512x64".

set PART    "xc7a35ticsg324-1L"   ;# <TARGET_PART>
set IP_DIR  "./ip"
set OUT_DIR "./ip/gen"
file mkdir $OUT_DIR

set_part $PART

# --- Example IP ------------------------------------------------------------
create_ip -name fifo_generator -vendor xilinx.com -library ip \
          -module_name fifo_512x64 -dir $IP_DIR
set_property -dict [list \
    CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
    CONFIG.Input_Data_Width     {64} \
    CONFIG.Input_Depth          {512} \
] [get_ips fifo_512x64]
generate_target all [get_ips fifo_512x64]
# synth_ip [get_ips fifo_512x64]   ;# optional: pre-synthesize the IP
# ---------------------------------------------------------------------------

puts "IP generation complete."
