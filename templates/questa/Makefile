# Makefile — cocotb on Questa (VHDL top). Default verification flow.
#
# RUN MANUALLY:
#   make                 # run the sim
#   make WAVES=1         # with waveform dump
#
# Requires: cocotb installed (pip install cocotb) and Questa on PATH.
# The fpga-testbench skill fills TOPLEVEL, MODULE, sources, and vendor libs.

SIM           ?= questa
TOPLEVEL_LANG ?= vhdl

# --- design sources --------------------------------------------------------
VHDL_SOURCES  += $(wildcard ../rtl/*.vhd)
# For a forced-Verilog IP core, add its sources:
# VERILOG_SOURCES += $(wildcard ../ip/gen/**/*.v)

# --- entry points ----------------------------------------------------------
TOPLEVEL      := <TOP_ENTITY>          # VHDL top entity name
MODULE        := <PYTHON_TEST_MODULE>  # e.g. test_top  (file test_top.py)

# --- vendor simulation libraries (from compile_simlib) ---------------------
SIM_ARGS      += -L secureip -L unisim -L xpm
# Point vsim at the compiled libs if not auto-mapped:
# SIM_ARGS    += -modelsimini ../sim/questa_libs/modelsim.ini

include $(shell cocotb-config --makefiles)/Makefile.sim
