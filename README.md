# 4×4 Systolic Array Accelerator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenLane](https://img.shields.io/badge/OpenLane-v1.0.0-blue)](https://github.com/The-OpenROAD-Project/OpenLane)
[![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm-orange)](https://github.com/google/skywater-pdk)

A fully open-source ASIC implementation of a high-throughput 4×4 systolic array accelerator for matrix multiplication, designed using the SkyWater 130nm PDK and OpenLane flow.

## 🌟 Project Overview

This project implements a fully pipelined Multiply-Accumulate (MAC) architecture with advanced handshaking protocols, achieving complete timing closure with excellent power efficiency. The design flows from RTL Verilog through synthesis, placement, Clock Tree Synthesis (CTS), and final routing with parasitic extraction.

### Key Achievements

- ✅ **Timing Closure**: Worst Setup Slack of **+5.67 ns** (Post-Route RCX)
- ⚡ **Low Power**: Total power consumption of **1.37 mW** at typical corner
- 🔧 **Zero Violations**: TNS = 0.00 ns, confirming manufacturability
- 📐 **Compact Design**: Core area of 2810.20 μm² with 215 standard cells
- 🌐 **100% Open-Source**: Complete ASIC flow using free tools

## 📋 Table of Contents

- [Architecture](#architecture)
- [Design Parameters](#design-parameters)
- [Getting Started](#getting-started)
- [Simulation](#simulation)
- [ASIC Flow](#asic-flow)
- [Performance Metrics](#performance-metrics)
- [File Structure](#file-structure)
- [Future Work](#future-work)
- [License](#license)

## 🏗️ Architecture

### Systolic Array Fundamentals

The systolic array is a specialized hardware accelerator that maximizes data reuse and parallelism. Data flows synchronously through the array in a "systolic pulse" pattern, minimizing off-chip memory access—the primary bottleneck in large-scale matrix operations.

### Processing Element (PE)

Each PE performs a single multiply-accumulate operation:

```
acc_reg ← acc_reg + (a_reg × b_reg)
```

**Key Features:**
- Fully pipelined MAC operation
- AXI-Stream-like valid/ready handshaking
- Non-blocking data flow with back-pressure support
- Prevents deadlocks in the array

### Data Flow

- **Horizontal (A-stream)**: Data flows left-to-right through rows
- **Vertical (B-stream)**: Data flows top-to-bottom through columns
- **Results**: Accumulated in each PE register

## ⚙️ Design Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| **M (Rows)** | 4 | Number of vertical PEs |
| **N (Columns)** | 4 | Number of horizontal PEs |
| **DATA_W** | 8 bits | Input data width for matrices A and B |
| **ACC_W** | 32 bits | Accumulator width (prevents overflow) |
| **PDK** | SkyWater 130nm | Standard cell library |
| **Clock Period** | 10 ns | Target frequency: 100 MHz |

## 🚀 Getting Started

### Prerequisites

Install the required open-source tools:

```bash
# Icarus Verilog (for simulation)
sudo apt-get install iverilog

# GTKWave (for waveform viewing)
sudo apt-get install gtkwave

# OpenLane (for ASIC flow)
# Follow instructions at: https://openlane.readthedocs.io/
```

### Clone Repository

```bash
git clone https://github.com/yourusername/systolic-array-accelerator.git
cd systolic-array-accelerator
```

## 🧪 Simulation

### Functional Verification

Run the testbench using Icarus Verilog:

```bash
# 1. Compile RTL and testbench
iverilog -o tb.out rtl/mac_pe.v rtl/systolic_top.v tb/tb_systolic.v

# 2. Run simulation and generate VCD
vvp tb.out

# 3. View waveforms
gtkwave tb_systolic_4x4.vcd
```

### Testbench Features

- Clock/reset generation (10ns period)
- Matrix multiplication stimulus
- Console output verification
- VCD waveform generation for debugging

## 🔨 ASIC Flow

### OpenLane Synthesis and Place & Route

```bash
# Navigate to OpenLane directory
cd openlane

# Run complete flow
make mount
./flow.tcl -design systolic_array
```

### Flow Stages

1. **Synthesis** (Yosys) - RTL to gate-level netlist
2. **Floorplanning** - Core area and I/O placement
3. **Placement** (RePlAce) - Standard cell placement
4. **CTS** (TritonCTS) - Clock tree synthesis
5. **Routing** (TritonRoute) - Detailed metal routing
6. **Parasitic Extraction** (RCX) - Final timing analysis
7. **GDSII Generation** - Mask-ready layout

## 📊 Performance Metrics

### Timing Analysis

| Metric | Post-Synthesis | Post-CTS | Post-Route (Final) |
|--------|----------------|----------|-------------------|
| **Worst Setup Slack** | +6.27 ns | +5.83 ns | **+5.67 ns** |
| **Worst Hold Slack** | +0.18 ns | +0.19 ns | **+0.29 ns** |
| **Total Negative Slack** | 0.00 ns | 0.00 ns | **0.00 ns** |
| **Clock Skew (Max)** | 0.03 ns | 0.02 ns | **0.02 ns** |

### Power Consumption (Typical Corner)

| Power Component | Post-Synthesis | Post-CTS | Post-Route (Final) |
|----------------|----------------|----------|-------------------|
| **Total Power** | 1.04 mW | 1.07 mW | **1.37 mW** |
| **Leakage Power** | 1.07 nW | 1.36 nW | **2.01 nW** |
| **Dynamic Power** | 1.04 mW | 1.07 mW | **1.37 mW** |
| Internal / Switching | 66.6% / 33.4% | 63.3% / 36.7% | **62.9% / 37.1%** |

### Area Utilization

- **Core Area**: 2810.20 μm²
- **Total Cells**: 215
  - Sequential (DFFs): 56
  - Combinational: 159
  - Inverters: 19
  - Buffers: 6

## 📁 File Structure

```
systolic-array-accelerator/
├── rtl/
│   ├── mac_pe.v              # Processing element (MAC unit)
│   └── systolic_top.v        # Top-level 4×4 array
├── tb/
│   └── tb_systolic.v         # Testbench for verification
├── reports/
│   ├── synthesis/
│   │   ├── 1-synthesis.DELAY_1.stat.rpt
│   │   └── 2-syn_sta.summary.rpt
│   ├── cts/
│   │   ├── 13-cts_sta.summary.rpt
│   │   └── 13-cts_sta.power.rpt
│   └── rcx/
│       ├── 31-rcx_sta.summary.rpt
│       ├── 31-rcx_sta.power.rpt
│       └── 31-rcx_sta.skew.rpt
├── layout/
│   └── systolic_array.gds    # Final GDSII layout
├── docs/
│   └── technical_report.md   # Detailed documentation
└── README.md
```

## 🔮 Future Work

### Planned Enhancements

1. **LVS/DRC Verification**
   - Complete Layout vs. Schematic verification
   - Final Design Rule Check for fabrication readiness

2. **External Interface Integration**
   - Full AXI-Stream compliance
   - SoC integration support

3. **Power Optimization**
   - Clock gating for unused PEs
   - Dynamic voltage/frequency scaling

4. **Scalability**
   - Parameterized designs for 8×8 and 16×16 arrays
   - Study of scaling impacts on timing and power

## 🛠️ Toolchain

| Tool | Stage | Version |
|------|-------|---------|
| **Icarus Verilog** | Simulation | v10.3+ |
| **GTKWave** | Waveform Analysis | Latest |
| **OpenLane** | Flow Orchestration | v1.0.0 |
| **Yosys** | Synthesis | 0.9+ |
| **OpenROAD** | Place & Route | Latest |
| **OpenSTA** | Timing Analysis | Latest |
| **Magic/KLayout** | Layout Viewing | Latest |

## 📄 License

This project is released under the MIT License. See [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request for:
- Bug fixes
- Performance improvements
- Documentation enhancements
- New features

## 📧 Contact

For questions, issues, or collaborations, please open an issue in this repository.

---

**Note**: This design is intended for educational and research purposes. For production use, additional verification and testing are recommended.

## 🙏 Acknowledgments

- SkyWater PDK team for the open-source 130nm PDK
- OpenLane community for the comprehensive ASIC flow
- All contributors to open-source EDA tools

## 📚 References

- [SkyWater PDK Documentation](https://skywater-pdk.readthedocs.io/)
- [OpenLane Documentation](https://openlane.readthedocs.io/)
- [Systolic Arrays Paper](https://www.eecs.harvard.edu/~htk/publication/1982-kung-why-systolic-architecture.pdf)
