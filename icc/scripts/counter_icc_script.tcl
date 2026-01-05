#============================================================
# IC Compiler Script for 8-bit Counter
# Project: counter8b
# Based on CPU project best practices
# V-FINAL-STABLE: Best achievable LVS result
#============================================================

set DESIGN_NAME    "counter_8bit"
set MW_LIB_NAME    "counter_8bit_Lib"

set LinkProject    "/home/ltk/ASIC_TRAINING/counter8b"
set LinkReport     "${LinkProject}/icc/reports"
set LinkNetlist    "${LinkProject}/dc/netlist"
set LinkSDC        "${LinkProject}/sdc"
set LinkLibrary_mk "/home/ltk/ASIC_LIB/Lib/process"
set LinkLibrary_db "/home/ltk/ASIC_LIB/Lib/syn_lib/syn_lib"

# Design variables
set Core_util      "0.7"
set Core_space     "3"

file mkdir ${LinkReport}

#------------------------------------------------------------
# 1. Setup Technology Files
#------------------------------------------------------------
set Techfile  "${LinkLibrary_mk}/astro/tech/astroTechFile.tf"
set Ref_lib   "${LinkLibrary_mk}/astro/fram/saed90nm_fr"
set Tlupmax   "${LinkLibrary_mk}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmax.tluplus"
set Tlupmin   "${LinkLibrary_mk}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmin.tluplus"
set Tech2itf  "${LinkLibrary_mk}/astro/tech/tech2itf.map"

set target_library [list ${LinkLibrary_db}/saed90nm_min.db \
                         ${LinkLibrary_db}/saed90nm_typ.db \
                         ${LinkLibrary_db}/saed90nm_max.db]

set link_library [list * ${LinkLibrary_db}/saed90nm_min.db \
                         ${LinkLibrary_db}/saed90nm_typ.db \
                         ${LinkLibrary_db}/saed90nm_max.db]

#------------------------------------------------------------
# 2. Create Milkyway Library
#------------------------------------------------------------
if {[file exists ${LinkProject}/icc/${MW_LIB_NAME}]} {
    file delete -force ${LinkProject}/icc/${MW_LIB_NAME}
}

create_mw_lib -technology $Techfile -mw_reference_library $Ref_lib ${LinkProject}/icc/${MW_LIB_NAME}

set_tlu_plus_files -max_tluplus $Tlupmax -min_tluplus $Tlupmin -tech2itf_map $Tech2itf
open_mw_lib "${LinkProject}/icc/${MW_LIB_NAME}"

#------------------------------------------------------------
# 3. Import Netlist
#------------------------------------------------------------
import_designs -format verilog -top $DESIGN_NAME -cel $DESIGN_NAME ${LinkNetlist}/${DESIGN_NAME}_NL.v

uniquify
link
uniquify_fp_mw_cel

read_sdc "${LinkSDC}/${DESIGN_NAME}_SDC.sdc"
save_mw_cel -as "${DESIGN_NAME}_imported"

#------------------------------------------------------------
# 4. Floorplanning
#------------------------------------------------------------
puts "=== FLOORPLANNING ==="

initialize_floorplan -core_utilization $Core_util -left_io2core $Core_space -bottom_io2core $Core_space -right_io2core $Core_space -top_io2core $Core_space

# Connect PG
derive_pg_connection -create_ports all -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS -tie

# Power Rings VDD (extend flags required for cell connection)
create_rectangular_rings -nets {VDD} -right_offset 1.0 -right_segment_layer M4 -right_segment_width 0.5 -left_offset 1.0 -left_segment_layer M4 -left_segment_width 0.5 \
-bottom_offset 1.0 -bottom_segment_layer M5 -bottom_segment_width 0.5 -top_offset 1.0 -top_segment_layer M5 -top_segment_width 0.5 -extend_tl -extend_th

# Power Rings VSS (extend flags required)
create_rectangular_rings -net {VSS} -left_offset 0.5 -left_segment_layer M5 -left_segment_width 0.5 -right_offset 0.5 -right_segment_layer M5 -right_segment_width 0.5 \
-bottom_offset 0.5 -bottom_segment_layer M5 -bottom_segment_width 0.5 -top_offset 0.5 -top_segment_layer M5 -top_segment_width 0.5 -extend_tl -extend_th

preroute_standard_cells -mode rail -nets "VSS VDD"

# NO Power Straps - not needed for small design (49 cells)

save_mw_cel -as "${DESIGN_NAME}_floorplan"

#------------------------------------------------------------
# 5. Placement (from CPU script)
#------------------------------------------------------------
puts "=== PLACEMENT ==="
place_opt -effort high

report_placement_utilization > ${LinkReport}/place_util.rpt

#------------------------------------------------------------
# 6. Clock Tree Synthesis (from CPU script)
#------------------------------------------------------------
puts "=== CTS ==="
clock_opt -only_cts -no_clock_route
clock_opt -no_clock_route -only_psyn -fix_hold_all_clocks

report_placement_utilization > ${LinkReport}/cts_util.rpt
report_qor > ${LinkReport}/cts_qor.rpt
report_timing -max_paths 20 -delay max > ${LinkReport}/cts_setup.rpt
report_timing -max_paths 20 -delay min > ${LinkReport}/cts_hold.rpt

save_mw_cel -as "${DESIGN_NAME}_cts"

#------------------------------------------------------------
# 7. Routing (from CPU script)
#------------------------------------------------------------
puts "=== ROUTING ==="
route_opt

report_placement_utilization > ${LinkReport}/route_util.rpt
report_qor > ${LinkReport}/route_qor.rpt
report_timing -max_paths 20 -delay max > ${LinkReport}/route_setup.rpt
report_timing -max_paths 20 -delay min > ${LinkReport}/route_hold.rpt

save_mw_cel -as "${DESIGN_NAME}_route"

#------------------------------------------------------------
# 8. Post-Route Cleanup (Enhanced for better PG connection)
#------------------------------------------------------------
puts "=== POST-ROUTE CLEANUP ==="

# Multiple derive_pg_connection calls to ensure all cells are connected
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS -tie
derive_pg_connection -power_net VDD -ground_net VSS -tie -cells [get_cells *]

# Preroute again to catch any missed connections
preroute_standard_cells -mode rail -nets "VSS VDD" -route_pins_on_layer M1

#------------------------------------------------------------
# 9. PG Verification and Fix
#------------------------------------------------------------
puts "=== PG VERIFICATION ==="

# Verify PG nets connection
verify_pg_nets -pad_pin_connection all > ${LinkReport}/pg_nets.rpt

# Analyze power rail
analyze_fp_rail -power_net VDD -ground_net VSS

# One more derive_pg_connection after analysis
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS -tie

#------------------------------------------------------------
# 10. Final Verification
#------------------------------------------------------------
puts "=== VERIFICATION ==="

verify_zrt_route > ${LinkReport}/drc.rpt
verify_lvs > ${LinkReport}/lvs.rpt

#------------------------------------------------------------
# 10. Export
#------------------------------------------------------------
puts "=== EXPORT ==="

write_verilog ${LinkProject}/icc/${DESIGN_NAME}_routed.v
write_sdf ${LinkProject}/icc/${DESIGN_NAME}_routed.sdf
write_def -output ${LinkProject}/icc/${DESIGN_NAME}.def

set_write_stream_options -child_depth 20 -flatten_via
write_stream -format gds -lib_name ${MW_LIB_NAME} ${LinkProject}/icc/${DESIGN_NAME}.gds

puts "=== ICC Complete ==="

