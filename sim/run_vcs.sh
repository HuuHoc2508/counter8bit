#!/bin/bash
#============================================================
# VCS Simulation Script for Counter8b
# Tool: Synopsys VCS (32-bit compatible)
# Author: ASIC Training
#============================================================

# Project paths
PROJECT_DIR="/home/ltk/ASIC_TRAINING/counter8b"
RTL_DIR="${PROJECT_DIR}/rtl"
SIM_DIR="${PROJECT_DIR}/sim"

# Create work directory
mkdir -p ${SIM_DIR}/work
cd ${SIM_DIR}/work

echo "============================================================"
echo "  VCS SIMULATION - COUNTER8B"
echo "============================================================"

#------------------------------------------------------------
# RTL Simulation (32-bit compatible - no -full64)
#------------------------------------------------------------
echo ""
echo "=== STAGE 1: RTL SIMULATION ==="
echo ""

# Compile with VCS (32-bit)
vcs -debug_all +v2k \
    -timescale=1ns/1ps \
    +vcs+vcdpluson \
    ${RTL_DIR}/counter_8bit.v \
    ${SIM_DIR}/counter_8bit_tb.v \
    -o simv_rtl \
    -l compile_rtl.log

if [ $? -eq 0 ]; then
    echo "[INFO] VCS Compilation successful"
    
    # Run simulation
    ./simv_rtl -l sim_rtl.log
    
    echo ""
    echo "[INFO] RTL Simulation complete"
    echo "[INFO] Log file: ${SIM_DIR}/work/sim_rtl.log"
    echo "[INFO] Waveform: ${SIM_DIR}/work/vcdplus.vpd"
else
    echo "[ERROR] VCS Compilation failed"
    echo "[INFO] Check compile_rtl.log for details"
    cat compile_rtl.log
fi

#------------------------------------------------------------
# Open waveform (optional)
#------------------------------------------------------------
echo ""
echo "=== WAVEFORM ==="
echo "To view waveform, run:"
echo "  dve -vpd vcdplus.vpd &"


