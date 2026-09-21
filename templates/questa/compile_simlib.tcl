# compile_simlib.tcl — compile Xilinx simulation libraries for Questa (ONE-TIME)
#
# RUN MANUALLY, once per Vivado/Questa version:
#   vivado -mode batch -source compile_simlib.tcl
#
# Produces Questa-usable libraries that the testbench references with -L.
# (Altera/Intel: use Quartus' equivalent library compilation instead.)

compile_simlib -simulator questa \
               -simulator_exec_path "$::env(QUESTA_BIN)" \
               -directory ./questa_libs \
               -family    all \
               -language  all \
               -library   all

puts "Sim libraries compiled to ./questa_libs"
puts "Reference them in the testbench Makefile with:  -L <lib> (e.g. -L secureip)"
