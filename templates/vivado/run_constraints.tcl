#==============================================================================
# run_constraints.tcl — constraints for <TOP>. Edited by fpga-toplevel.
# User/pin XDC first, then IP-specific XDC (UG903 processing order).
#==============================================================================
set _here [file normalize [file dirname [info script]]]
set _unit [file normalize $_here/..]

# read_xdc $_unit/xdc/<top>_pins.xdc
# read_xdc $_unit/xdc/<top>_timing.xdc
