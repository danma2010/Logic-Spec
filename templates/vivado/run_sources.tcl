#==============================================================================
# run_sources.tcl — RTL hierarchy + IP for <TOP>. Edited by fpga-toplevel.
# Read BOTTOM-UP: leaf sub-units first, then composites, then the top.
#==============================================================================

# --- sub-unit RTL (validated units instantiated by direct RTL) ---------------
# read_vhdl ../../<leaf_unit>/rtl/<leaf>.vhd
# read_vhdl ../../<composite_unit>/rtl/<composite>.vhd

# --- this unit's RTL ---------------------------------------------------------
# read_vhdl ../rtl/<top>.vhd

# --- vendor IP (.xci) --------------------------------------------------------
# read_ip  ../tcl/ip/<ip>.xci
# generate_target all [get_ips]
