#============================================================
# Design Compiler Script for 8-bit Counter
# Project: counter8b
# Based on CPU project best practices
# Target: Optimize timing and area
#============================================================

set DESIGN_NAME    "counter_8bit"
set LinkProject    "/home/ltk/ASIC_TRAINING/counter8b"
set LinkLibrary_db "/home/ltk/ASIC_LIB/Lib/syn_lib/syn_lib/"
set LinkSource     "${LinkProject}/rtl"
set LinkReport     "${LinkProject}/dc/reports"
set LinkNetlist    "${LinkProject}/dc/netlist"
set LinkSDC        "${LinkProject}/sdc"

# Create output directories
file mkdir ${LinkReport}
file mkdir ${LinkNetlist}
file mkdir ${LinkSDC}

#------------------------------------------------------------
# 1. Setup Technology Library
#------------------------------------------------------------
define_design_lib WORK -path "work"

set target_library [list ${LinkLibrary_db}/saed90nm_min.db \
                         ${LinkLibrary_db}/saed90nm_typ.db \
                         ${LinkLibrary_db}/saed90nm_max.db]

set link_library [list * ${LinkLibrary_db}/saed90nm_min.db \
                         ${LinkLibrary_db}/saed90nm_typ.db \
                         ${LinkLibrary_db}/saed90nm_max.db]

#------------------------------------------------------------
# 2. Read and Analyze RTL
#------------------------------------------------------------
analyze -format verilog ${LinkSource}/${DESIGN_NAME}.v

elaborate ${DESIGN_NAME}

current_design ${DESIGN_NAME}

link
uniquify

check_design > ${LinkReport}/check_design.rpt

#------------------------------------------------------------
# 3. Setup Operating Conditions (from CPU)
#------------------------------------------------------------
set_min_library "${LinkLibrary_db}/saed90nm_max.db" -min_version "${LinkLibrary_db}/saed90nm_min.db"
set_operating_conditions -min BEST -max WORST

#------------------------------------------------------------
# 4. Timing Constraints (Optimized for less slack)
#------------------------------------------------------------
# Clock: 0.7ns period = 1.43 GHz (testing Fmax)
set CLK_PERIOD 0.7
set CLK_NAME "Clk"

# Transition and uncertainty
set tran [expr 0.05 * $CLK_PERIOD]
set delay_in [expr 0.2 * $CLK_PERIOD]
set delay_out [expr 0.2 * $CLK_PERIOD]

# Create clock
create_clock -period $CLK_PERIOD -waveform [list 0 [expr $CLK_PERIOD/2]] [get_ports $CLK_NAME]

# Clock properties
set_clock_uncertainty $tran [get_clocks $CLK_NAME]
set_clock_latency $tran [get_clocks $CLK_NAME]
set_clock_transition $tran [get_clocks $CLK_NAME]

# Input delays (exclude clock and reset)
set_input_delay $delay_in [remove_from_collection [all_inputs] [get_ports {Clk Reset}]] -clock $CLK_NAME
set_input_delay [expr 0.1 * $CLK_PERIOD] [get_ports Reset] -clock $CLK_NAME

# Output delays
set_output_delay $delay_out [all_outputs] -clock $CLK_NAME

#------------------------------------------------------------
# 5. Path Groups (from CPU script)
#------------------------------------------------------------
group_path -name "Inputs" -from [all_inputs]
group_path -name "Outputs" -to [all_outputs]
group_path -name "Combo" -from [all_inputs] -to [all_outputs]

#------------------------------------------------------------
# 6. Drive and Load
#------------------------------------------------------------
set_driving_cell -lib_cell INVX1 [all_inputs]
set_load 0.01 [all_outputs]

#------------------------------------------------------------
# 7. Compile with High Effort (from CPU)
#------------------------------------------------------------
compile -area_effort high -map_effort high

# Second pass for better optimization
compile -incremental_mapping

#------------------------------------------------------------
# 8. Generate Reports
#------------------------------------------------------------
report_area > ${LinkReport}/area.rpt
report_cell > ${LinkReport}/cells.rpt
report_qor > ${LinkReport}/qor.rpt
report_resources > ${LinkReport}/resources.rpt
report_timing -max_paths 20 > ${LinkReport}/timing.rpt
report_timing -delay max > ${LinkReport}/setup_timing.rpt
report_timing -delay min > ${LinkReport}/hold_timing.rpt
report_power > ${LinkReport}/power.rpt

#------------------------------------------------------------
# 9. Name Rules and Export
#------------------------------------------------------------
define_name_rules my_rules -allowed {a-zA-Z0-9_} -first_restricted "_" -last_restricted "_" -max_length 255
change_names -rules my_rules -hierarchy
change_names -rules verilog -hierarchy

# Export SDC and Netlist
write_sdc ${LinkSDC}/${DESIGN_NAME}_SDC.sdc
write -hierarchy -format verilog -output ${LinkNetlist}/${DESIGN_NAME}_NL.v

puts "=== DC Synthesis Complete ==="



