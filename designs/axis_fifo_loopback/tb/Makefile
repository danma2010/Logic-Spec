# tb/Makefile — cocotb on Questa for axis_fifo_loopback.
#
# RUN MANUALLY (preferred — test by test + report):
#   bash tools/run_tests.sh axis_fifo_loopback
# Quick smoke, all tests in one run:
#   cd designs/axis_fifo_loopback/tb && make            # real top + XPM (default)
#   make FAST=1                                          # behavioural FIFO, no vendor libs
#   make WAVES=1                                         # waveform dump
#
# Default = the unit's real top with the XPM model (needs simlibs/questa from
# tools/compile_simlib.tcl). Only the default configuration counts for
# validation (gate 3); FAST=1 is for quick iteration.

UNIT_DIR      := $(abspath ..)
REPO          := $(abspath ../../..)

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
  SIMLIB_INI   := $(REPO)/simlibs/questa/modelsim.ini
  ifneq ($(wildcard $(SIMLIB_INI)),)
    $(shell [ -f modelsim.ini ] || cp $(SIMLIB_INI) modelsim.ini)
  else
    $(warning simlibs/questa not found — run tools/compile_simlib.tcl, or use FAST=1)
  endif
  SIM_ARGS     += -L xpm -L unisim
endif

MODULE        := test_axis_fifo_loopback

include $(shell cocotb-config --makefiles)/Makefile.sim
