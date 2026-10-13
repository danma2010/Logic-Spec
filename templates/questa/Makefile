# tb/Makefile — cocotb on Questa (VHDL top). Default verification flow.
# Filled in by fpga-testbench. Paths are absolute, so make works from tb/.
#
# RUN MANUALLY (preferred — test by test + report):
#   bash tools/run_tests.sh <unit>
# Quick smoke (all tests, one simulator run):
#   cd designs/<unit>/tb && make            # add WAVES=1 for a waveform dump
#
# Requires cocotb (pip install cocotb) and Questa on PATH.

UNIT_DIR      := $(abspath ..)
REPO          := $(abspath ../../..)

SIM           ?= questa
TOPLEVEL_LANG ?= vhdl

# --- design sources: validated sub-units FIRST (bottom-up), then this unit ---
# VHDL_SOURCES += $(REPO)/designs/<child>/rtl/<child_module>.vhd
# VHDL_SOURCES += $(REPO)/designs/<child>/rtl/<child_top>.vhd
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
SIMLIB_INI    := $(REPO)/simlibs/questa/modelsim.ini
ifneq ($(wildcard $(SIMLIB_INI)),)
  $(shell [ -f modelsim.ini ] || cp $(SIMLIB_INI) modelsim.ini)
  SIM_ARGS    += -L xpm -L unisim -L secureip
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
