# build_bd.tcl — Xilinx block design (IP Integrator) INSIDE a unit.
# Emitted to designs/<unit>/bd/build_bd.tcl by fpga-blockdesign.
# The BD wrapper is instantiated by the unit's RTL top (rtl/<top>.vhd); it is
# never the unit's top itself (CLAUDE.md, reuse = direct RTL instantiation).
#
# RUN MANUALLY (from any directory, after build_ip.tcl if the BD uses its IP):
#   vivado -mode batch -source designs/<unit>/bd/build_bd.tcl

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set UNIT_DIR   [file normalize $SCRIPT_DIR/..]
set PART       "<PART>"           ;# = architecture.md `part:`
set DESIGN     "<unit>_bd"

# IP Integrator needs a project; an in-memory one keeps the flow scripted.
create_project -in_memory -part $PART

# RTL used as module-reference cells must be read before create_bd_cell.
# Note: module references cannot point at VHDL-2008-only files; keep those
# modules VHDL-93 compatible or wrap them.
# read_vhdl $UNIT_DIR/rtl/<module>.vhd

create_bd_design -dir $SCRIPT_DIR $DESIGN

# --- Cells (example) --------------------------------------------------------
# create_bd_cell -type ip     -vlnv xilinx.com:ip:fifo_generator fifo_0
# create_bd_cell -type module -reference <module> ctrl_0
#
# --- Connections (example) — connect EVERY input, incl. resets ---------------
# connect_bd_net      [get_bd_pins ctrl_0/clk] [get_bd_pins fifo_0/wr_clk]
# connect_bd_intf_net [get_bd_intf_pins ...]   [get_bd_intf_pins ...]
# make_bd_pins_external [get_bd_pins ctrl_0/<port>]
# ---------------------------------------------------------------------------

validate_bd_design
save_bd_design
make_wrapper -files [get_files ${DESIGN}.bd] -top
generate_target all [get_files ${DESIGN}.bd]
puts "Block design assembled: $SCRIPT_DIR/$DESIGN (wrapper ${DESIGN}_wrapper)"
