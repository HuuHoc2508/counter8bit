#!/bin/bash
#============================================================
# Automation Script for Counter8b Verification
# Runs: RTL simulation, Post-synthesis simulation
# Tools: Icarus Verilog (iverilog) / ModelSim / VCS
# Author: ASIC Training
#============================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project paths
PROJECT_DIR="/home/ltk/ASIC_TRAINING/counter8b"
RTL_DIR="${PROJECT_DIR}/rtl"
SIM_DIR="${PROJECT_DIR}/sim"
DC_NET_DIR="${PROJECT_DIR}/dc/netlist"
LIB_DIR="/home/ltk/ASIC_LIB/Lib"

# Create sim directory if not exists
mkdir -p ${SIM_DIR}
mkdir -p ${SIM_DIR}/work

echo "============================================================"
echo "  COUNTER8B VERIFICATION AUTOMATION"
echo "  Date: $(date)"
echo "============================================================"

#------------------------------------------------------------
# Function: Run RTL Simulation
#------------------------------------------------------------
run_rtl_simulation() {
    echo ""
    echo -e "${YELLOW}=== STAGE 1: RTL SIMULATION ===${NC}"
    echo ""
    
    cd ${SIM_DIR}
    
    # Using Icarus Verilog (open source)
    if command -v iverilog &> /dev/null; then
        echo "[INFO] Using Icarus Verilog for RTL simulation"
        
        # Compile RTL
        iverilog -o counter_8bit_rtl.vvp \
            -s counter_8bit_tb \
            ${RTL_DIR}/counter_8bit.v \
            ${SIM_DIR}/counter_8bit_tb.v
        
        if [ $? -eq 0 ]; then
            echo "[INFO] Compilation successful"
            
            # Run simulation
            vvp counter_8bit_rtl.vvp | tee rtl_sim.log
            
            # Check results
            if grep -q "ALL TESTS PASSED" rtl_sim.log; then
                echo -e "${GREEN}[PASS] RTL Simulation PASSED${NC}"
                return 0
            else
                echo -e "${RED}[FAIL] RTL Simulation FAILED${NC}"
                return 1
            fi
        else
            echo -e "${RED}[ERROR] RTL Compilation failed${NC}"
            return 1
        fi
    
    # Using ModelSim
    elif command -v vsim &> /dev/null; then
        echo "[INFO] Using ModelSim for RTL simulation"
        
        cd ${SIM_DIR}/work
        
        # Compile
        vlog ${RTL_DIR}/counter_8bit.v
        vlog ${SIM_DIR}/counter_8bit_tb.v
        
        # Run
        vsim -c -do "run -all; quit" counter_8bit_tb | tee ../rtl_sim.log
        
        if grep -q "ALL TESTS PASSED" ../rtl_sim.log; then
            echo -e "${GREEN}[PASS] RTL Simulation PASSED${NC}"
            return 0
        else
            echo -e "${RED}[FAIL] RTL Simulation FAILED${NC}"
            return 1
        fi
        
    # Using VCS
    elif command -v vcs &> /dev/null; then
        echo "[INFO] Using VCS for RTL simulation"
        
        vcs -full64 -debug_all \
            ${RTL_DIR}/counter_8bit.v \
            ${SIM_DIR}/counter_8bit_tb.v \
            -o simv
        
        ./simv | tee rtl_sim.log
        
        if grep -q "ALL TESTS PASSED" rtl_sim.log; then
            echo -e "${GREEN}[PASS] RTL Simulation PASSED${NC}"
            return 0
        else
            echo -e "${RED}[FAIL] RTL Simulation FAILED${NC}"
            return 1
        fi
    else
        echo -e "${RED}[ERROR] No Verilog simulator found (iverilog/vsim/vcs)${NC}"
        return 1
    fi
}

#------------------------------------------------------------
# Function: Run Post-Synthesis Simulation
#------------------------------------------------------------
run_gate_simulation() {
    echo ""
    echo -e "${YELLOW}=== STAGE 2: POST-SYNTHESIS SIMULATION ===${NC}"
    echo ""
    
    cd ${SIM_DIR}
    
    # Check if netlist exists
    if [ ! -f "${DC_NET_DIR}/counter_8bit_NL.v" ]; then
        echo -e "${RED}[ERROR] Netlist not found: ${DC_NET_DIR}/counter_8bit_NL.v${NC}"
        echo "[INFO] Please run DC synthesis first"
        return 1
    fi
    
    # Library files (Verilog models for simulation)
    SAED_VERILOG="${LIB_DIR}/verilog/saed90nm.v"
    
    # Using Icarus Verilog
    if command -v iverilog &> /dev/null; then
        echo "[INFO] Using Icarus Verilog for gate-level simulation"
        
        # Check if library exists
        if [ -f "${SAED_VERILOG}" ]; then
            LIB_OPT="${SAED_VERILOG}"
        else
            echo "[WARN] SAED library not found, using minimal simulation"
            LIB_OPT=""
        fi
        
        # Compile gate-level netlist
        iverilog -o counter_8bit_gate.vvp \
            -s counter_8bit_gate_tb \
            ${LIB_OPT} \
            ${DC_NET_DIR}/counter_8bit_NL.v \
            ${SIM_DIR}/counter_8bit_gate_tb.v
        
        if [ $? -eq 0 ]; then
            echo "[INFO] Gate-level compilation successful"
            
            # Run simulation
            vvp counter_8bit_gate.vvp | tee gate_sim.log
            
            if grep -q "ALL GATE-LEVEL TESTS PASSED" gate_sim.log; then
                echo -e "${GREEN}[PASS] Gate-Level Simulation PASSED${NC}"
                return 0
            else
                echo -e "${RED}[FAIL] Gate-Level Simulation FAILED${NC}"
                return 1
            fi
        else
            echo -e "${RED}[ERROR] Gate-level compilation failed${NC}"
            return 1
        fi
    
    # Using ModelSim with SDF
    elif command -v vsim &> /dev/null; then
        echo "[INFO] Using ModelSim for gate-level simulation with SDF"
        
        cd ${SIM_DIR}/work
        
        # Compile library
        vlog ${LIB_DIR}/verilog/saed90nm.v
        
        # Compile netlist
        vlog ${DC_NET_DIR}/counter_8bit_NL.v
        vlog ${SIM_DIR}/counter_8bit_gate_tb.v
        
        # Run with SDF annotation
        vsim -c -sdfmax /DUT=${DC_NET_DIR}/counter_8bit_NL.sdf \
            -do "run -all; quit" counter_8bit_gate_tb | tee ../gate_sim.log
        
        if grep -q "ALL GATE-LEVEL TESTS PASSED" ../gate_sim.log; then
            echo -e "${GREEN}[PASS] Gate-Level Simulation PASSED${NC}"
            return 0
        else
            echo -e "${RED}[FAIL] Gate-Level Simulation FAILED${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}[WARN] Skipping gate-level simulation (no compatible simulator)${NC}"
        return 0
    fi
}

#------------------------------------------------------------
# Function: Generate Report
#------------------------------------------------------------
generate_report() {
    echo ""
    echo -e "${YELLOW}=== VERIFICATION REPORT ===${NC}"
    echo ""
    
    cd ${SIM_DIR}
    
    cat > verification_report.txt << EOF
============================================================
  COUNTER8B VERIFICATION REPORT
  Date: $(date)
============================================================

1. RTL SIMULATION
-----------------
EOF
    
    if [ -f rtl_sim.log ]; then
        grep -E "TEST SUMMARY|Total Tests|Passed|Failed|PASSED|FAILED" rtl_sim.log >> verification_report.txt
    else
        echo "Not executed" >> verification_report.txt
    fi
    
    cat >> verification_report.txt << EOF

2. GATE-LEVEL SIMULATION
------------------------
EOF
    
    if [ -f gate_sim.log ]; then
        grep -E "TEST SUMMARY|Total Tests|Passed|Failed|PASSED|FAILED|GHz" gate_sim.log >> verification_report.txt
    else
        echo "Not executed" >> verification_report.txt
    fi
    
    cat >> verification_report.txt << EOF

3. WAVEFORMS
------------
- RTL: ${SIM_DIR}/counter_8bit_tb.vcd
- Gate: ${SIM_DIR}/counter_8bit_gate_tb.vcd

============================================================
EOF

    cat verification_report.txt
}

#------------------------------------------------------------
# Main Execution
#------------------------------------------------------------

RTL_RESULT=0
GATE_RESULT=0

# Run RTL simulation
run_rtl_simulation
RTL_RESULT=$?

# Run gate-level simulation
run_gate_simulation
GATE_RESULT=$?

# Generate report
generate_report

# Final summary
echo ""
echo "============================================================"
echo "  FINAL SUMMARY"
echo "============================================================"

if [ $RTL_RESULT -eq 0 ] && [ $GATE_RESULT -eq 0 ]; then
    echo -e "${GREEN}  ALL VERIFICATIONS PASSED${NC}"
    exit 0
else
    echo -e "${RED}  SOME VERIFICATIONS FAILED${NC}"
    exit 1
fi
