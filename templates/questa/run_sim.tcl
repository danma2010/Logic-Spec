# run_sim.tcl — plain Questa compile + run (SV/UVM path only, non-cocotb).
# Emitted to <design>/sim/run_sim.tcl by fpga-questa when the plan flags UVM.
#
# RUN MANUALLY (from any directory):
#   vsim -c -do <design>/sim/run_sim.tcl

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set UNIT_DIR   [file normalize $SCRIPT_DIR/..]   ;# the design folder
# framework root (shared sim libraries); env LOGIC_SPEC overrides
set LOGIC_SPEC [expr {[info exists ::env(LOGIC_SPEC)] ? $::env(LOGIC_SPEC) : "{{LOGIC_SPEC}}"}]
cd $SCRIPT_DIR                    ;# work library + transcript live in sim/

set SIMLIB_INI $LOGIC_SPEC/simlibs/questa/modelsim.ini
if {[file exists $SIMLIB_INI] && ![file exists modelsim.ini]} {
    file copy $SIMLIB_INI modelsim.ini
}

vlib work
vmap work work

# --- compile: sub-units first (bottom-up), then this unit, then the tb -------
# vcom -2008 [file normalize $UNIT_DIR/<dep>]/rtl/<file>.vhd   ;# <dep> = dependency path from architecture.md
vcom -2008 {*}[glob $UNIT_DIR/rtl/*.vhd]
# vlog -sv $UNIT_DIR/tb/<tb>.sv

# --- optimize with vendor libs, run -----------------------------------------
vopt +acc <TB_TOP> -o tb_opt -L xpm -L unisim -L secureip
vsim -c tb_opt -do "run -all; quit -f"

# Results: transcript. For UVM, parse the UVM_ERROR / UVM_FATAL summary lines.
