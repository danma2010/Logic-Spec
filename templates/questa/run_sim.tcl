# run_sim.tcl — plain Questa compile + run (SV/UVM path, non-cocotb)
#
# RUN MANUALLY:
#   vsim -c -do run_sim.tcl
#
# Used only when the plan flags UVM. For the default cocotb flow use the tb/Makefile.

vlib work
vmap work work

# --- compile (VHDL first, then any Verilog/SV) -----------------------------
vcom -2008 ../rtl/*.vhd
# vlog -sv ../tb/*.sv ../ip/gen/**/*.v

# --- optimize with vendor libs ---------------------------------------------
vopt +acc <TOP> -o <TOP>_opt -L secureip -L unisim -L xpm

# --- run -------------------------------------------------------------------
vsim -c <TOP>_opt -do "run -all; quit -f"

# Results: transcript (+ coverage/assertions if enabled). For UVM, parse the
# UVM_ERROR/UVM_FATAL summary lines.
