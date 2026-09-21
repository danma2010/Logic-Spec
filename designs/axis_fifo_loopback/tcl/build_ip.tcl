# build_ip.tcl — generate the dual-clock FWFT FIFO for axis_fifo_loopback.
#
# RUN MANUALLY:
#   vivado -mode batch -source build_ip.tcl
#
# Resolves the abstract "dual-clock FIFO 512x64, FWFT" to a Xilinx FIFO Generator.

set PART   "xc7a35ticsg324-1L"   ;# <-- adjust to your target part
set IP_DIR "./ip"
file mkdir $IP_DIR
set_part $PART

create_ip -name fifo_generator -vendor xilinx.com -library ip \
          -module_name fifo_512x64 -dir $IP_DIR

set_property -dict [list \
    CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width    {64} \
    CONFIG.Input_Depth         {512} \
    CONFIG.Output_Data_Width   {64} \
    CONFIG.Output_Depth        {512} \
] [get_ips fifo_512x64]

generate_target all [get_ips fifo_512x64]
puts "fifo_512x64 generated in $IP_DIR"
