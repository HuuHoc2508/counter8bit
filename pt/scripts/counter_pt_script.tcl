#============================================================
# PrimeTime Script for 8-bit Counter
# Project: counter8b
# Based on CPU project best practices
# Features: ECO fixes for timing and DRC
#============================================================

set DESIGN_NAME    "counter_8bit"
set LinkProject    "/home/ltk/ASIC_TRAINING/counter8b"
set LinkLibrary_db "/home/ltk/ASIC_LIB/Lib/syn_lib/syn_lib/"
set LinkReport     "${LinkProject}/pt/reports"
set LinkNetlist    "${LinkProject}/dc/netlist"
set LinkSDC        "${LinkProject}/sdc"

# Create output directories
file mkdir ${LinkReport}

#------------------------------------------------------------
# 1. Setup Technology Library
#------------------------------------------------------------
set target_library [list ${LinkLibrary_db}/saed90nm_min.db \
                         ${LinkLibrary_db}/saed90nm_typ.db \
                         ${LinkLibrary_db}/saed90nm_max.db]

set link_library [list * ${LinkLibrary_db}/saed90nm_min.db \
                         ${LinkLibrary_db}/saed90nm_typ.db \
                         ${LinkLibrary_db}/saed90nm_max.db]

#------------------------------------------------------------
# 2. Read Netlist
#------------------------------------------------------------
read_verilog ${LinkNetlist}/${DESIGN_NAME}_NL.v

current_design ${DESIGN_NAME}
link

#------------------------------------------------------------
# 3. Read Constraints
#------------------------------------------------------------
source ${LinkSDC}/${DESIGN_NAME}_SDC.sdc

#------------------------------------------------------------
# 4. ECO Fixes (from CPU script)
#------------------------------------------------------------
puts "--- Fixing Hold Violations ---"
fix_eco_timing -type hold -buffer_list {NBUFFX2 NBUFFX4 NBUFFX8}

puts "--- Fixing Max Transition DRC ---"
fix_eco_drc -type max_transition -buffer_list {NBUFFX2 NBUFFX4 NBUFFX8}

puts "--- Fixing Max Capacitance DRC ---"
fix_eco_drc -type max_capacitance -buffer_list {NBUFFX2 NBUFFX4 NBUFFX8}

#------------------------------------------------------------
# 5. Generate Timing Reports
#------------------------------------------------------------
puts "--- Generating Timing Reports ---"

# Path type reports
report_timing -max_paths 20 -from [all_inputs] -to [all_registers -data_pins] > ${LinkReport}/inputs_to_flops.rpt
report_timing -max_paths 20 -from [all_registers -clock_pins] -to [all_registers -data_pins] > ${LinkReport}/flop_to_flop.rpt
report_timing -max_paths 20 -from [all_registers -clock_pins] -to [all_outputs] > ${LinkReport}/flops_to_outputs.rpt
report_timing -max_paths 20 -from [all_inputs] -to [all_outputs] > ${LinkReport}/inputs_to_outputs.rpt

# Setup and Hold timing
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -delay_type max > ${LinkReport}/setup_timing.rpt
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -delay_type min > ${LinkReport}/hold_timing.rpt

# Transition and capacitance
report_timing -transition_time -capacitance -nets -input_pins -from [all_registers -clock_pins] -to [all_registers -data_pins] > ${LinkReport}/tran_cap_timing.rpt

# DRC violations
report_constraint -all_violators > ${LinkReport}/drc_violations.rpt

#------------------------------------------------------------
# 6. Export Fixed Netlist
#------------------------------------------------------------
write_verilog -hierarchy -output ${LinkNetlist}/${DESIGN_NAME}_pt_NL.v

puts "=== PrimeTime Analysis Complete ==="
exit
