#==============================================================================
# run_sources.tcl — RTL hierarchy + IP for <TOP>. Edited by fpga-toplevel
# (impl/run_sources.tcl) and fpga-auto (build/synth_sources.tcl, same format).
# Paths are resolved from this file's location, so it can be sourced from anywhere.
# Read BOTTOM-UP: leaf sub-units first, then composites, then this unit.
#==============================================================================
set _here [file normalize [file dirname [info script]]]
set _unit [file normalize $_here/..]           ;# designs/<unit>
set _designs [file normalize $_unit/..]        ;# designs/

# --- sub-unit RTL + IP (validated units, direct RTL instantiation) -----------
# read_vhdl -vhdl2008 [glob $_designs/<leaf_unit>/rtl/*.vhd]
# read_ip   $_designs/<leaf_unit>/tcl/ip/<ip>/<ip>.xci

# --- this unit's RTL ---------------------------------------------------------
read_vhdl -vhdl2008 [glob $_unit/rtl/*.vhd]

# --- this unit's vendor IP (.xci from tcl/build_ip.tcl) ----------------------
# read_ip $_unit/tcl/ip/<ip>/<ip>.xci
# --- block design (if any) ---------------------------------------------------
# read_bd $_unit/bd/<unit>_bd/<unit>_bd.bd

# generate_target all [get_ips]
