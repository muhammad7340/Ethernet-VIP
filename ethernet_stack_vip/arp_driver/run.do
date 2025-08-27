#vlib work
#vlog packet_generator.sv 
#vsim -sv_lib my_dpi test
#run

vlib work
vlog +acc ./rtl/*
vlog +acc packet_generator.sv udp_test.sv
vsim -sv_lib my_dpi work.udp_test
add wave -position insertpoint  \
sim:/udp_test/* 
run 1000