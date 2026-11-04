# tb/Makefile — cocotb on Questa for axis_fifo_loopback.
#
# RUN MANUALLY (preferred — test by test + report):
#   bash $(LOGIC_SPEC)/tools/run_tests.sh .        (from the design folder)
# Quick smoke, all tests in one run:
#   cd tb && make                                       # real top + XPM (default)
#   make FAST=1                                          # behavioural FIFO, no vendor libs
#   make WAVES=1                                         # waveform dump
#
# Default = the unit's real top with the XPM model (needs $(LOGIC_SPEC)/simlibs/questa
# from tools/compile_simlib.tcl). Only the default configuration counts for
# validation (gate 3); FAST=1 is for quick iteration.

UNIT_DIR      := $(abspath ..)
# framework root (shared sim libraries). This example lives in <LOGIC_SPEC>/examples/;
# a design elsewhere sets the absolute framework path here.
LOGIC_SPEC    ?= $(abspath ../../..)

SIM           ?= questa
TOPLEVEL_LANG ?= vhdl
COMPILE_ARGS  += -2008

VHDL_SOURCES  += $(UNIT_DIR)/rtl/axis_fifo_ctrl.vhd

ifeq ($(FAST),1)
  VHDL_SOURCES += $(UNIT_DIR)/tb/fifo_model.vhd
  VHDL_SOURCES += $(UNIT_DIR)/tb/sim_top.vhd
  TOPLEVEL     := sim_top
else
  VHDL_SOURCES += $(UNIT_DIR)/rtl/axis_fifo_loopback.vhd
  TOPLEVEL     := axis_fifo_loopback
  SIMLIB_INI   := $(LOGIC_SPEC)/simlibs/questa/modelsim.ini
  ifneq ($(wildcard $(SIMLIB_INI)),)
    $(shell [ -f modelsim.ini ] || cp $(SIMLIB_INI) modelsim.ini)
  else
    $(warning $(LOGIC_SPEC)/simlibs/questa not found — run tools/compile_simlib.tcl, or use FAST=1)
  endif
  SIM_ARGS     += -L xpm -L unisim
endif

MODULE        := test_axis_fifo_loopback

include $(shell cocotb-config --makefiles)/Makefile.sim
