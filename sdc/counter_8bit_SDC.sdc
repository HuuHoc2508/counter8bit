###################################################################

# Created by write_sdc on Sun Jun 18 16:03:22 2017

###################################################################
set sdc_version 1.8

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
set_operating_conditions -max WORST -max_library saed90nm_max\
                         -min BEST -min_library saed90nm_min
set_driving_cell -lib_cell INVX1 [get_ports Clk]
set_driving_cell -lib_cell INVX1 [get_ports Reset]
set_driving_cell -lib_cell INVX1 [get_ports E]
set_driving_cell -lib_cell INVX1 [get_ports M]
set_load -pin_load 0.01 [get_ports {Q[7]}]
set_load -pin_load 0.01 [get_ports {Q[6]}]
set_load -pin_load 0.01 [get_ports {Q[5]}]
set_load -pin_load 0.01 [get_ports {Q[4]}]
set_load -pin_load 0.01 [get_ports {Q[3]}]
set_load -pin_load 0.01 [get_ports {Q[2]}]
set_load -pin_load 0.01 [get_ports {Q[1]}]
set_load -pin_load 0.01 [get_ports {Q[0]}]
set_load -pin_load 0.01 [get_ports Cout]
create_clock [get_ports Clk]  -period 0.7  -waveform {0 0.35}
set_clock_latency 0.035  [get_clocks Clk]
set_clock_uncertainty 0.035  [get_clocks Clk]
set_clock_transition -fall 0.035 [get_clocks Clk]
set_clock_transition -rise 0.035 [get_clocks Clk]
group_path -name Combo  -from [list [get_ports Clk] [get_ports Reset] [get_ports E] [get_ports M]]  -to [list [get_ports {Q[7]}] [get_ports {Q[6]}] [get_ports {Q[5]}] [get_ports \
{Q[4]}] [get_ports {Q[3]}] [get_ports {Q[2]}] [get_ports {Q[1]}] [get_ports    \
{Q[0]}] [get_ports Cout]]
group_path -name Inputs  -from [list [get_ports Clk] [get_ports Reset] [get_ports E] [get_ports M]]
group_path -name Outputs  -to [list [get_ports {Q[7]}] [get_ports {Q[6]}] [get_ports {Q[5]}] [get_ports \
{Q[4]}] [get_ports {Q[3]}] [get_ports {Q[2]}] [get_ports {Q[1]}] [get_ports    \
{Q[0]}] [get_ports Cout]]
set_input_delay -clock Clk  0.07  [get_ports Reset]
set_input_delay -clock Clk  0.14  [get_ports E]
set_input_delay -clock Clk  0.14  [get_ports M]
set_output_delay -clock Clk  0.14  [get_ports {Q[7]}]
set_output_delay -clock Clk  0.14  [get_ports {Q[6]}]
set_output_delay -clock Clk  0.14  [get_ports {Q[5]}]
set_output_delay -clock Clk  0.14  [get_ports {Q[4]}]
set_output_delay -clock Clk  0.14  [get_ports {Q[3]}]
set_output_delay -clock Clk  0.14  [get_ports {Q[2]}]
set_output_delay -clock Clk  0.14  [get_ports {Q[1]}]
set_output_delay -clock Clk  0.14  [get_ports {Q[0]}]
set_output_delay -clock Clk  0.14  [get_ports Cout]
