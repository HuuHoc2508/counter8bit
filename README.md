# 8-bit Up/Down Counter ASIC Design

A complete ASIC design project implementing an 8-bit synchronous up/down counter using standard cell methodology.

## 📊 Key Results

| Metric | Value |
|--------|-------|
| **Technology** | SAED 90nm (not included) |
| **Frequency** | 1.43 GHz (synthesis) / 910 MHz (verified) |
| **Setup Slack** | +0.05 ns |
| **Hold Slack** | +0.07 ns |
| **Area** | 693 µm² |
| **Cell Count** | 56 cells |
| **DRC/LVS** | Clean ✅ |

## 🏗️ Project Structure

```
counter8bit/
├── rtl/                    # Verilog RTL source
│   └── counter_8bit.v
├── sdc/                    # Timing constraints
│   └── counter_8bit.sdc
├── dc/                     # Design Compiler
│   ├── scripts/
│   └── reports/
├── pt/                     # PrimeTime
│   ├── scripts/
│   └── reports/
├── icc/                    # IC Compiler
│   ├── scripts/
│   └── reports/
└── sim/                    # Simulation
    ├── counter_8bit_tb.v       # RTL testbench
    ├── counter_8bit_gate_tb.v  # Gate-level testbench
    └── run_*.sh
```

## 🔧 Design Flow

```
RTL → Design Compiler → PrimeTime (ECO) → IC Compiler → Signoff
```

1. **Synthesis (DC):** RTL to gate-level netlist @ 1.43 GHz
2. **Timing Analysis (PT):** ECO fix with 8× NBUFFX2 buffer insertion
3. **Place & Route (ICC):** Floorplan, CTS, Routing
4. **Verification:** DRC/LVS clean, gate-level simulation

## ⚙️ Tools Required

- Synopsys Design Compiler
- Synopsys PrimeTime
- Synopsys IC Compiler
- Synopsys VCS (simulation)
- SAED 90nm Standard Cell Library (not included)

## 📋 Prerequisites

> ⚠️ **Note:** This project uses SAED 90nm technology library which is **not included** due to licensing restrictions. You need to obtain the library separately from Synopsys.

Required library files:
- `saed90nm_min.db`, `saed90nm_typ.db`, `saed90nm_max.db`
- `saed90nm.v` (Verilog models)
- TLU+ files for RC extraction
- Milkyway reference library

## 🚀 How to Run

```bash
# 1. Synthesis
cd dc && dc_shell -f scripts/counter_dc_script.tcl

# 2. Timing Analysis & ECO
cd pt && pt_shell -f scripts/counter_pt_script.tcl

# 3. Place & Route
cd icc && icc_shell -f scripts/counter_icc_script.tcl

# 4. Simulation
cd sim && ./run_vcs.sh        # RTL sim
cd sim && ./run_gate_vcs.sh   # Gate-level sim
```

## 📈 Verification Results

| Test Level | Clock | Tests | Status |
|------------|-------|-------|--------|
| RTL | 1.43 GHz | 10/10 | ✅ PASS |
| Gate-Level | 910 MHz | 5/5 | ✅ PASS |

## 📝 License

RTL code and scripts are provided for educational purposes.

> **Important:** Technology library files (SAED 90nm) are proprietary to Synopsys and are NOT included in this repository.

## 👤 Author

ASIC Training Project - December 2025
