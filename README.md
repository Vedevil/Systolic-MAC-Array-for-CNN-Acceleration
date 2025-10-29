#!/bin/bash
# ============================================================================
# Complete OpenLane & SKY130 PDK Workflow - Bash Commands
# RTL to GDSII for Systolic MAC Array
# ============================================================================

# ============================================================================
# STEP 1: INSTALLATION & SETUP
# ============================================================================

echo "=== Step 1: Installing OpenLane ==="

# Clone OpenLane repository
cd $HOME
git clone https://github.com/The-OpenROAD-Project/OpenLane.git
cd OpenLane

# Build Docker image and install dependencies (downloads PDKs automatically)
make

# Verify installation
make test

# Expected output: All tests should pass
# [IMAGE PLACEHOLDER: OpenLane installation success]

# ============================================================================
# STEP 2: CREATE DESIGN DIRECTORY STRUCTURE
# ============================================================================

echo "=== Step 2: Setting up Design Structure ==="

# Navigate to designs directory
cd $HOME/OpenLane/designs

# Create design folder structure
mkdir -p systolic_mac_array/src
mkdir -p systolic_mac_array/constraints
mkdir -p systolic_mac_array/results

cd systolic_mac_array

# Verify directory structure
tree .
# Expected output:
# .
# ├── src/
# ├── constraints/
# └── results/

# [IMAGE PLACEHOLDER: Directory structure tree view]

# ============================================================================
# STEP 3: COPY/CREATE RTL FILES
# ============================================================================

echo "=== Step 3: Creating RTL Design Files ==="

# NOTE: You should have already created:
# - src/mac_pe.v
# - src/systolic_top.v
# - src/tb_systolic.v
# (Use the code provided in the document)

# Verify RTL files exist
ls -la src/
# Expected output:
# mac_pe.v
# systolic_top.v
# tb_systolic.v

# [IMAGE PLACEHOLDER: List of RTL files]

# ============================================================================
# STEP 4: RUN SYNTHESIS WITH YOSYS (STANDALONE)
# ============================================================================

echo "=== Step 4: Running Yosys Synthesis ==="

# Enter OpenLane container
cd $HOME/OpenLane
make mount

# Inside the container, navigate to your design
cd /openlane/designs/systolic_mac_array/src

# Run Yosys synthesis with the script
yosys -s ../synth.ys

# Alternative: Interactive Yosys session
yosys <<EOF
read_liberty -lib /openlane/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog mac_pe.v
read_verilog systolic_top.v
hierarchy -top systolic_top
synth -top systolic_top
dfflibmap -liberty /openlane/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty /openlane/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
clean
write_verilog -noattr synth_netlist.v
stat -liberty /openlane/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
tee -o synth_stats.txt stat
EOF

# Check synthesis output
ls -lh synth_netlist.v

# View synthesis statistics
cat synth_stats.txt

# [IMAGE PLACEHOLDER: Yosys synthesis statistics output]

# ============================================================================
# STEP 5: POST-SYNTHESIS FUNCTIONAL SIMULATION
# ============================================================================

echo "=== Step 5: Post-Synthesis Simulation ==="

# Locate standard cell Verilog models
PDK_VERILOG="/openlane/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
PDK_VERILOG2="/openlane/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"

# Compile with iverilog (Icarus Verilog)
iverilog -g2012 -o tb_netlist.vvp \
  tb_systolic.v \
  synth_netlist.v \
  $PDK_VERILOG \
  $PDK_VERILOG2

# Run simulation
vvp tb_netlist.vvp

# View waveforms (if GTKWave is available)
gtkwave systolic_tb.vcd &

# [IMAGE PLACEHOLDER: GTKWave waveform viewer screenshot]

# Alternative: Using Verilator for faster simulation
verilator --cc --exe --build -j 0 \
  --top-module systolic_top \
  systolic_top.v mac_pe.v tb_systolic.cpp

./obj_dir/Vsystolic_top

# [IMAGE PLACEHOLDER: Simulation output results]

# ============================================================================
# STEP 6: RUN COMPLETE OPENLANE FLOW (RTL → GDSII)
# ============================================================================

echo "=== Step 6: Running Full OpenLane Flow ==="

# Enter OpenLane container (if not already inside)
cd $HOME/OpenLane
make mount

# Inside container, run OpenLane flow
cd /openlane

# Run complete RTL to GDSII flow
./flow.tcl -design systolic_mac_array -tag run1 -overwrite

# Alternative: Run with custom config
./flow.tcl -design systolic_mac_array \
  -tag run1 \
  -overwrite \
  -config_file /openlane/designs/systolic_mac_array/config.json

# Monitor flow progress
tail -f /openlane/designs/systolic_mac_array/runs/run1/logs/flow_summary.log

# [IMAGE PLACEHOLDER: OpenLane flow execution progress]

# ============================================================================
# STEP 7: RUN SPECIFIC FLOW STAGES
# ============================================================================

echo "=== Step 7: Running Individual Stages ==="

# Synthesis only
./flow.tcl -design systolic_mac_array -tag run2 -from synthesis -to synthesis

# Floorplan only
./flow.tcl -design systolic_mac_array -tag run2 -from floorplan -to floorplan

# Placement only
./flow.tcl -design systolic_mac_array -tag run2 -from placement -to placement

# Clock Tree Synthesis (CTS)
./flow.tcl -design systolic_mac_array -tag run2 -from cts -to cts

# Routing
./flow.tcl -design systolic_mac_array -tag run2 -from routing -to routing

# Complete flow from synthesis to routing
./flow.tcl -design systolic_mac_array -tag run2 -from synthesis -to routing

# [IMAGE PLACEHOLDER: Individual stage completion logs]

# ============================================================================
# STEP 8: CHECK RESULTS
# ============================================================================

echo "=== Step 8: Analyzing Results ==="

# Navigate to results directory
cd /openlane/designs/systolic_mac_array/runs/run1/results

# List all result files
ls -lR

# Check final GDSII
ls -lh final/gds/systolic_top.gds

# Check final netlist
ls -lh final/verilog/gl/systolic_top.v

# Check final DEF
ls -lh final/def/systolic_top.def

# Check final LEF
ls -lh final/lef/systolic_top.lef

# [IMAGE PLACEHOLDER: Results directory listing]

# ============================================================================
# STEP 9: VIEW LAYOUT WITH KLAYOUT
# ============================================================================

echo "=== Step 9: Viewing GDSII Layout ==="

# Open GDSII with KLayout (requires X11 forwarding or local installation)
klayout /openlane/designs/systolic_mac_array/runs/run1/results/final/gds/systolic_top.gds

# Alternative: Magic VLSI viewer
magic -T /openlane/pdks/sky130A/libs.tech/magic/sky130A.tech \
  /openlane/designs/systolic_mac_array/runs/run1/results/final/gds/systolic_top.gds

# [IMAGE PLACEHOLDER: KLayout GDSII viewer showing layout]

# ============================================================================
# STEP 10: CHECK REPORTS
# ============================================================================

echo "=== Step 10: Reviewing Reports ==="

cd /openlane/designs/systolic_mac_array/runs/run1/reports

# View synthesis report
cat synthesis/1-synthesis.stat.rpt.strategy0

# View area report
cat final_summary_report.csv

# View timing report
cat signoff/sta-rcx_nom/multi_corner_sta.checks.rpt

# View power report
cat signoff/sta-rcx_nom/multi_corner_sta.power.rpt

# View DRC report
cat signoff/drc/drc.rpt

# View LVS report
cat signoff/lvs/lvs.rpt

# [IMAGE PLACEHOLDER: Timing report excerpt]
# [IMAGE PLACEHOLDER: Power report excerpt]

# Generate summary
cat /openlane/designs/systolic_mac_array/runs/run1/reports/final_summary_report.csv

# ============================================================================
# STEP 11: EXTRACT KEY METRICS
# ============================================================================

echo "=== Step 11: Extracting Key Metrics ==="

# Extract timing slack
grep -A 5 "worst slack" \
  /openlane/designs/systolic_mac_array/runs/run1/reports/signoff/sta-rcx_nom/multi_corner_sta.checks.rpt

# Extract total cell area
grep "Chip area" \
  /openlane/designs/systolic_mac_array/runs/run1/reports/synthesis/1-synthesis.stat.rpt.strategy0

# Extract cell count
grep "Number of cells" \
  /openlane/designs/systolic_mac_array/runs/run1/reports/synthesis/1-synthesis.stat.rpt.strategy0

# Extract wire length
grep "Total wire length" \
  /openlane/designs/systolic_mac_array/runs/run1/reports/routing/detailed_routing.drc

# Extract power consumption
grep "Total Power" \
  /openlane/designs/systolic_mac_array/runs/run1/reports/signoff/sta-rcx_nom/multi_corner_sta.power.rpt

# [IMAGE PLACEHOLDER: Summary metrics table]

# ============================================================================
# STEP 12: RUN DRC/LVS VERIFICATION
# ============================================================================

echo "=== Step 12: Running DRC/LVS Checks ==="

# DRC check with Magic
cd /openlane/designs/systolic_mac_array/runs/run1/results/final/gds

magic -T /openlane/pdks/sky130A/libs.tech/magic/sky130A.tech \
  -noconsole -dnull <<EOF
gds read systolic_top.gds
load systolic_top
select top cell
expand
drc check
drc catchup
drc count
drc why
quit -noprompt
EOF

# LVS check with Netgen
netgen -batch lvs \
  "/openlane/designs/systolic_mac_array/runs/run1/results/final/verilog/gl/systolic_top.v systolic_top" \
  "/openlane/designs/systolic_mac_array/runs/run1/results/final/gds/systolic_top.gds systolic_top" \
  /openlane/pdks/sky130A/libs.tech/netgen/sky130A_setup.tcl \
  systolic_top_lvs.out

# Check LVS results
cat systolic_top_lvs.out | grep -A 10 "Circuit"

# [IMAGE PLACEHOLDER: DRC/LVS results summary]

# ============================================================================
# STEP 13: GENERATE FINAL DOCUMENTATION
# ============================================================================

echo "=== Step 13: Generating Documentation ==="

cd /openlane/designs/systolic_mac_array/runs/run1

# Create summary report
cat > design_summary.txt <<EOF
=== Systolic MAC Array Design Summary ===
Design: systolic_top
Technology: SKY130A
Run Tag: run1
Date: $(date)

--- Key Metrics ---
EOF

# Append metrics
grep "Total cells" reports/synthesis/1-synthesis.stat.rpt.strategy0 >> design_summary.txt
grep "Chip area" reports/synthesis/1-synthesis.stat.rpt.strategy0 >> design_summary.txt
grep "worst slack" reports/signoff/sta-rcx_nom/multi_corner_sta.checks.rpt >> design_summary.txt

cat design_summary.txt

# [IMAGE PLACEHOLDER: Final design summary document]

# ============================================================================
# STEP 14: COPY RESULTS TO HOST SYSTEM
# ============================================================================

echo "=== Step 14: Exporting Results ==="

# Exit container (Ctrl+D or exit)
exit

# On host system, results are available at:
cd $HOME/OpenLane/designs/systolic_mac_array/runs/run1

# Copy important files to a results folder
mkdir -p $HOME/systolic_array_results
cp results/final/gds/systolic_top.gds $HOME/systolic_array_results/
cp results/final/verilog/gl/systolic_top.v $HOME/systolic_array_results/
cp reports/final_summary_report.csv $HOME/systolic_array_results/
cp -r logs $HOME/systolic_array_results/

# Create archive
cd $HOME
tar -czf systolic_array_results.tar.gz systolic_array_results/

ls -lh systolic_array_results.tar.gz

echo "=== OpenLane Flow Complete! ==="
echo "Results archived at: $HOME/systolic_array_results.tar.gz"

# [IMAGE PLACEHOLDER: Final exported results directory]

# ============================================================================
# USEFUL DEBUGGING COMMANDS
# ============================================================================

# View OpenLane logs in real-time
tail -f $HOME/OpenLane/designs/systolic_mac_array/runs/run1/logs/openlane.log

# Check for errors
grep -i "error" $HOME/OpenLane/designs/systolic_mac_array/runs/run1/logs/openlane.log

# Check for warnings
grep -i "warning" $HOME/OpenLane/designs/systolic_mac_array/runs/run1/logs/openlane.log

# Clean up old runs
rm -rf $HOME/OpenLane/designs/systolic_mac_array/runs/run1

# Re-run with different parameters
cd $HOME/OpenLane
make mount
./flow.tcl -design systolic_mac_array -tag run2 -overwrite

# [IMAGE PLACEHOLDER: Debug log output]

# ============================================================================
# END OF SCRIPT
# ============================================================================
