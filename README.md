# Systolic-MAC-Array-for-CNN-Acceleration
This repository contains the complete RTL-to-GDSII flow for implementing a systolic array architecture using the SkyWater SKY130 open-source PDK and OpenLane. The project demonstrates the digital ASIC design flow from synthesis to layout, targeting a custom matrix multiplication accelerator core.

install full open source tool chain for sky130

then go for synhtesis 
'''bash 
read_liberty -lib ../lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog mac_pe.v
read_verilog systolic_top.v
hierarchy -top systolic_top
synth -top systolic_top
dfflibmap -liberty ../lib/sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty ../lib/sky130_fd_sc_hd__tt_025C_1v80.lib
clean
write_verilog -noattr synth_netlist.v
stat -liberty ../lib/sky130_fd_sc_hd__tt_025C_1v80.lib
show systolic_top
'''
