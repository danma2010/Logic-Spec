# build_bd.tcl — assemble the Xilinx block design in Tcl (IP Integrator)
#
# RUN MANUALLY:
#   vivado -mode batch -source build_bd.tcl
#
# The fpga-blockdesign skill fills the cells and connections from the plan.

set DESIGN "system"

create_bd_design $DESIGN

# --- Cells (example) -------------------------------------------------------
# create_bd_cell -type ip  -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_0
# create_bd_cell -type module -reference my_ctrl  ctrl_0     ;# custom RTL ref
#
# --- Connections (example) -------------------------------------------------
# connect_bd_net       [get_bd_pins ctrl_0/clk]  [get_bd_pins fifo_0/wr_clk]
# connect_bd_intf_net  [get_bd_intf_pins ...]    [get_bd_intf_pins ...]
# ---------------------------------------------------------------------------

validate_bd_design
save_bd_design
make_wrapper -files [get_files ${DESIGN}.bd] -top

puts "Block design assembled: ${DESIGN}"
