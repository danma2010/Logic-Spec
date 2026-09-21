# cocotb on Questa — fast functional loop for axis_fifo_loopback.
# Uses the behavioural FIFO model, so no vendor IP setup is needed.
#
# RUN MANUALLY:
#   cd designs/axis_fifo_loopback/tb && make
#   make WAVES=1     # with waveform dump
#
# Requires: cocotb (pip install cocotb) and Questa on PATH.

SIM           ?= questa
TOPLEVEL_LANG ?= vhdl

VHDL_SOURCES += $(PWD)/../rtl/axis_fifo_ctrl.vhd
VHDL_SOURCES += $(PWD)/fifo_model.vhd
VHDL_SOURCES += $(PWD)/sim_top.vhd

TOPLEVEL := sim_top
MODULE   := test_axis_fifo_loopback

include $(shell cocotb-config --makefiles)/Makefile.sim
