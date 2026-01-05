#!/bin/bash
#============================================================
# VCS Gate-Level Simulation Script
# Runs post-synthesis netlist verification
#============================================================

PROJECT_DIR="/home/ltk/ASIC_TRAINING/counter8b"
SIM_DIR="${PROJECT_DIR}/sim"
DC_NET_DIR="${PROJECT_DIR}/dc/netlist"
LIB_DIR="/home/ltk/ASIC_LIB/Lib"

mkdir -p ${SIM_DIR}/work
cd ${SIM_DIR}/work

echo "============================================================"
echo "  VCS GATE-LEVEL SIMULATION"
echo "============================================================"

#------------------------------------------------------------
# Check for library models
#------------------------------------------------------------
SAED_LIB=""
if [ -f "${LIB_DIR}/syn_lib/model/saed90nm.v" ]; then
    SAED_LIB="${LIB_DIR}/syn_lib/model/saed90nm.v"
    echo "[INFO] Using SAED library: ${SAED_LIB}"
elif [ -f "${LIB_DIR}/verilog/saed90nm.v" ]; then
    SAED_LIB="${LIB_DIR}/verilog/saed90nm.v"
    echo "[INFO] Using SAED library: ${SAED_LIB}"
elif [ -f "/home/eda/saed90nm/SAED90_EDK/SAED_EDK90nm/Digital_Standard_Cell_Library/verilog/saed90nm.v" ]; then
    SAED_LIB="/home/eda/saed90nm/SAED90_EDK/SAED_EDK90nm/Digital_Standard_Cell_Library/verilog/saed90nm.v"
    echo "[INFO] Using SAED library: ${SAED_LIB}"
else
    echo "[WARN] SAED Verilog library not found!"
    echo "[INFO] Looking for library..."
    FOUND_LIB=$(find /home -name "saed90nm.v" 2>/dev/null | head -1)
    if [ -n "${FOUND_LIB}" ]; then
        SAED_LIB="${FOUND_LIB}"
        echo "[INFO] Found library: ${SAED_LIB}"
    fi
fi

#------------------------------------------------------------
# Compile Gate-Level Simulation
#------------------------------------------------------------
echo ""
echo "=== COMPILING GATE-LEVEL SIMULATION ==="
echo ""

if [ -n "${SAED_LIB}" ]; then
    # Use combined ECO netlist (DW01_inc + PT ECO top module)
    vcs -debug_all +v2k \
        -timescale=1ns/1ps \
        +vcs+vcdpluson \
        +define+UNIT_DELAY \
        ${SAED_LIB} \
        ${DC_NET_DIR}/counter_8bit_eco_NL.v \
        ${SIM_DIR}/counter_8bit_gate_tb.v \
        -o simv_gate \
        -l compile_gate.log
else
    echo "[ERROR] Cannot compile without library models"
    echo "[INFO] Please provide path to saed90nm.v"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "[INFO] Gate-level compilation successful"
    
    # Run simulation
    echo ""
    echo "=== RUNNING GATE-LEVEL SIMULATION ==="
    ./simv_gate -l sim_gate.log
    
    echo ""
    echo "[INFO] Gate-level simulation complete"
    echo "[INFO] Log: ${SIM_DIR}/work/sim_gate.log"
else
    echo "[ERROR] Gate-level compilation failed"
    cat compile_gate.log
fi

echo ""
echo "=== WAVEFORM ==="
echo "  dve -vpd vcdplus.vpd &"


