# tb/Makefile — cocotb on Questa (VHDL top). Default verification flow.
# Filled in by fpga-testbench. Paths are absolute, so make works from tb/.
#
# RUN MANUALLY (preferred — test by test + report):
#   bash <LOGIC_SPEC>/tools/run_tests.sh <design>
# Quick smoke (all tests, one simulator run):
#   cd <design>/tb && make            # add WAVES=1 for a waveform dump
#
# Requires cocotb (pip install cocotb) and Questa on PATH.

UNIT_DIR      := $(abspath ..)
# framework root (shared sim libraries); filled in by fpga-testbench
LOGIC_SPEC    ?= {{LOGIC_SPEC}}

SIM           ?= questa
TOPLEVEL_LANG ?= vhdl

# --- design sources: validated sub-units FIRST (bottom-up), then this unit ---
# <dep> = a `dependencies` path from spec/architecture.md (relative to the design folder)
# VHDL_SOURCES += $(abspath $(UNIT_DIR)/<dep>)/rtl/<child_module>.vhd
# VHDL_SOURCES += $(abspath $(UNIT_DIR)/<dep>)/rtl/<child_top>.vhd
VHDL_SOURCES  += $(UNIT_DIR)/rtl/<module>.vhd
VHDL_SOURCES  += $(UNIT_DIR)/rtl/<top>.vhd
# Forced-Verilog IP sim sources (from tcl/ip/), if any:
# VERILOG_SOURCES += ...
COMPILE_ARGS  += -2008

# --- entry points: the unit's REAL top (architecture.md `top:`) --------------
TOPLEVEL      := <top>
MODULE        := test_<unit>

# --- vendor simulation libraries (tools/compile_simlib.tcl, shared) ---------
# A local modelsim.ini copied from the shared one maps xpm/unisim/... for both
# vcom and vsim; cocotb then adds its work library to the local copy.
SIMLIB_INI    := $(LOGIC_SPEC)/simlibs/questa/modelsim.ini
ifneq ($(wildcard $(SIMLIB_INI)),)
  $(shell [ -f modelsim.ini ] || cp $(SIMLIB_INI) modelsim.ini)
  SIM_ARGS    += -L xpm -L unisim -L secureip
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
