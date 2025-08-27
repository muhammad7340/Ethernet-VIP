# to see only transcript with packets genration
#vlib work
#vlog packet_generator.sv 
#vsim -sv_lib my_dpi test
#run

#to see arp_test uncoment
#vlib work
#vlog +acc ./rtl/* ./lib/axis/rtl/*.v
#vlog +acc packet_generator.sv arp_test.sv
#vsim -sv_lib my_dpi work.arp_test
##add wave -position insertpoint  \
#sim:/arp_test/* 
#run 1000



#to see ip_rx_test
#change the testfile_name and module name with work.
#vlib work
#vlog +acc ./rtl/* ./lib/axis/rtl/*.v
#vlog +acc packet_generator.sv ip_rx_test.sv
#vsim -sv_lib my_dpi work.ip_rx_test
#add wave -position insertpoint  \
#sim:/ip_rx_test/* 
#run 1000

#add wave -position insertpoint sim:/ip_rx_test/dut/clk
#add wave -position insertpoint sim:/ip_rx_test/dut/s_eth*
#add wave -position insertpoint sim:/ip_rx_test/dut/m_ip*
#add wave -position insertpoint sim:/ip_rx_test/dut/m_ip_payload_axis_tready*
#add wave -position insertpoint sim:/ip_rx_test/dut/ip_complete_64_inst/ip_inst/s*
#add wave -position insertpoint ip_rx_test/dut/ip_complete_64_inst/ip_inst/ip_eth_rx_64_inst/s_eth*
#add wave -position insertpoint ip_rx_test/dut/ip_complete_64_inst/m_ip_payload_axis_tready*
#add wave -position insertpoint ip_rx_test/dut/ip_complete_64_inst/ip_inst/m_ip_payload_axis_tready*
#add wave -position insertpoint ip_rx_test/dut/ip_complete_64_inst/ip_inst/ip_eth_rx_64_inst/*
#add wave -position insertpoint sim:/ip_rx_test/dut/m_eth*
#run 700


# to see ip_tx_test
vlib work
vlog +acc ./rtl/* ./lib/axis/rtl/*.v
vlog +acc packet_generator.sv ip_tx_test.sv
vsim -wlfdeleteonquit -sv_lib  my_dpi work.ip_tx_test
add wave -position insertpoint sim:/ip_tx_test/dut/clk
add wave -position insertpoint sim:/ip_tx_test/dut/ip_rx_error_invalid_checksum
add wave -position insertpoint sim:/ip_tx_test/dut/s_eth*
add wave -position insertpoint sim:/ip_tx_test/dut/m_eth*
add wave -position insertpoint sim:/ip_tx_test/dut/m_ip*