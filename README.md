#!/usr/bin/env bash
# ============================================================================
# openlane_run.sh
# Nicely formatted RTL -> GDSII OpenLane workflow driver for Systolic MAC Array
# Usage: ./openlane_run.sh [--design NAME] [--tag TAG] [--force] [--dry-run]
# Example: ./openlane_run.sh --design systolic_mac_array --tag run1
# ============================================================================

set -o errexit
set -o pipefail
set -o nounset

# -------------------------
# CONFIGURABLE VARIABLES
# -------------------------
OPENLANE_REPO="${HOME}/OpenLane"
DESIGNS_DIR="${OPENLANE_REPO}/designs"
DEFAULT_DESIGN="systolic_mac_array"
DEFAULT_TAG="run1"
PDK_REL_PATH="pdks/sky130A" # relative to OpenLane root (used for hints)
YOSYS_SCRIPT="../synth.ys"   # relative to design/src when running inside container
LOGDIR="${HOME}/openlane_runs"  # host-side archive of run logs/results

# -------------------------
# CLI / ARGS
# -------------------------
DESIGN="${DEFAULT_DESIGN}"
TAG="${DEFAULT_TAG}"
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --design) DESIGN="$2"; shift 2;;
    --tag) TAG="$2"; shift 2;;
    --force) FORCE=true; shift;;
    --dry-run) DRY_RUN=true; shift;;
    -h|--help) 
      cat <<EOF
Usage: $0 [--design NAME] [--tag TAG] [--force] [--dry-run]
  --design   Name of design folder under OpenLane/designs (default: ${DEFAULT_DESIGN})
  --tag      Run tag used by flow.tcl (default: ${DEFAULT_TAG})
  --force    Re-clone OpenLane if missing / overwrite some checks (use with care)
  --dry-run  Echo steps but don't execute heavy commands
EOF
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

# -------------------------
# COLORS (optional)
# -------------------------
if [[ -t 1 ]]; then
  RED="$(printf '\033[1;31m')"
  GREEN="$(printf '\033[1;32m')"
  YELLOW="$(printf '\033[1;33m')"
  BLUE="$(printf '\033[1;34m')"
  BOLD="$(printf '\033[1;1m')"
  RESET="$(printf '\033[0m')"
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

# -------------------------
# HELPERS
# -------------------------
logfile="${LOGDIR}/${DESIGN}_${TAG}_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "${logfile}")"

step() {
  local title="$1"
  echo
  echo -e "${BOLD}${BLUE}===> ${title}${RESET}"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] STEP: ${title}" | tee -a "${logfile}"
}

run() {
  # run a command, echo it to stdout & logfile; if dry-run, only echo
  echo -e "${YELLOW}+ $*${RESET}"
  echo "+ $*" >> "${logfile}"
  if ! $DRY_RUN; then
    eval "$@" 2>&1 | tee -a "${logfile}"
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" &>/dev/null; then
    echo -e "${RED}Error: required command '${cmd}' not found in PATH.${RESET}"
    echo "Please install it or run this script from a system with ${cmd} available."
    exit 2
  fi
}

# -------------------------
# SANITY CHECKS (host)
# -------------------------
step "Sanity checks and environment"
echo "Design: ${DESIGN}, Tag: ${TAG}, Dry-run: ${DRY_RUN}, Force: ${FORCE}"
echo "Logfile: ${logfile}"

# Check required host tools for local steps (not everything is required inside container)
for c in git docker; do
  if ! command -v "${c}" &>/dev/null; then
    echo -e "${YELLOW}Warning: '${c}' not found. Some steps may fail or require you to run inside container.${RESET}"
  fi
done

# -------------------------
# STEP 1: Clone OpenLane (if needed)
# -------------------------
step "Step 1: Install / prepare OpenLane"

if [[ ! -d "${OPENLANE_REPO}" || "${FORCE}" == "true" ]]; then
  if [[ -d "${OPENLANE_REPO}" && "${FORCE}" == "true" ]]; then
    echo -e "${YELLOW}Forcing re-clone of OpenLane (removing existing).${RESET}"
    run "rm -rf \"${OPENLANE_REPO}\""
  fi
  run "git clone https://github.com/The-OpenROAD-Project/OpenLane.git \"${OPENLANE_REPO}\""
  cd "${OPENLANE_REPO}"
  echo -e "${GREEN}Building OpenLane (this downloads and builds PDKs). This may take a while.${RESET}"
  run "make"
  run "make test || echo 'make test returned non-zero; check ${OPENLANE_REPO}/test results.'"
else
  echo "OpenLane already exists at ${OPENLANE_REPO}"
fi

# -------------------------
# STEP 2: Create design folder structure
# -------------------------
step "Step 2: Create design structure under OpenLane/designs"

DESIGN_DIR="${DESIGNS_DIR}/${DESIGN}"
SRC_DIR="${DESIGN_DIR}/src"
CONSTRAINTS_DIR="${DESIGN_DIR}/constraints"
RESULTS_DIR="${DESIGN_DIR}/results"

if [[ ! -d "${DESIGN_DIR}" ]]; then
  run "mkdir -p \"${SRC_DIR}\" \"${CONSTRAINTS_DIR}\" \"${RESULTS_DIR}\""
  echo -e "${GREEN}Created design skeleton: ${DESIGN_DIR}${RESET}"
else
  echo "Design folder already exists: ${DESIGN_DIR}"
fi

# List expected RTL files to help user confirm
echo "Expected RTL files (place them into ${SRC_DIR}):"
echo "  - mac_pe.v"
echo "  - systolic_top.v"
echo "  - tb_systolic.v"
ls -la "${SRC_DIR}" || true

# -------------------------
# STEP 3: Confirm RTL files exist
# -------------------------
step "Step 3: Verify RTL files are present"
missing=()
for f in mac_pe.v systolic_top.v tb_systolic.v; do
  if [[ ! -f "${SRC_DIR}/${f}" ]]; then
    missing+=("${f}")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo -e "${RED}Missing RTL files in ${SRC_DIR}:${RESET} ${missing[*]}"
  echo "Please copy your RTL into the src/ folder before continuing."
  if $DRY_RUN; then
    echo "Dry-run: continuing anyway."
  else
    exit 3
  fi
else
  echo -e "${GREEN}All required RTL files found.${RESET}"
fi

# -------------------------
# STEP 4: Run Yosys synthesis (inside container recommended)
# -------------------------
step "Step 4: Run Yosys synthesis (recommended inside OpenLane container)"

echo "We will launch 'make mount' to open a shell inside the OpenLane container and run synthesis."
if $DRY_RUN; then
  echo "Dry-run: would run OpenLane container and then run yosys -s ${YOSYS_SCRIPT} inside ${DESIGN_DIR}/src"
else
  run "cd \"${OPENLANE_REPO}\" && make mount"  # opens interactive container shell in interactive use
  echo -e "${BLUE}Now inside container shell. Run the following inside the container:${RESET}"
  cat <<EOF
cd /openlane/designs/${DESIGN}/src
# Option A: run provided script (if you put synth.ys next to src/)
yosys -s ${YOSYS_SCRIPT}

# Option B: run interactive Yosys session (if you want to paste your commands)
yosys
# then run:
# read_liberty -lib /openlane/${PDK_REL_PATH}/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# read_verilog mac_pe.v
# read_verilog systolic_top.v
# hierarchy -top systolic_top
# synth -top systolic_top
# dfflibmap -liberty /openlane/${PDK_REL_PATH}/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# abc -liberty /openlane/${PDK_REL_PATH}/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# clean
# write_verilog -noattr synth_netlist.v
# stat -liberty /openlane/${PDK_REL_PATH}/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
EOF
  echo -e "${YELLOW}After running yosys, ensure synth_netlist.v was generated in ${SRC_DIR}${RESET}"
fi

# -------------------------
# STEP 5: Post-synthesis functional simulation (host or container)
# -------------------------
step "Step 5: Run post-synthesis functional simulation"

if $DRY_RUN; then
  echo "Dry-run: would invoke iverilog with synth_netlist.v and PDK verilog models."
else
  # Compose PDK verilog locations (inside container these paths differ)
  PDK_V_PRIM="${OPENLANE_REPO}/${PDK_REL_PATH}/libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
  PDK_V_ALL="${OPENLANE_REPO}/${PDK_REL_PATH}/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"

  # If running inside container, these paths are /openlane/..., user must adapt if needed.
  if [[ -f "${SRC_DIR}/synth_netlist.v" ]]; then
    run "iverilog -g2012 -o \"${SRC_DIR}/tb_netlist.vvp\" \
      \"${SRC_DIR}/tb_systolic.v\" \
      \"${SRC_DIR}/synth_netlist.v\" \
      \"${PDK_V_PRIM}\" \
      \"${PDK_V_ALL}\"" || echo "iverilog compile returned non-zero (check paths and files)."
    if [[ -f "${SRC_DIR}/tb_netlist.vvp" ]]; then
      run "vvp \"${SRC_DIR}/tb_netlist.vvp\""
      echo -e "${GREEN}Post-synthesis simulation completed (check waveform/synth logs).${RESET}"
    else
      echo -e "${RED}tb_netlist.vvp not created. Skipping simulation run.${RESET}"
    fi
  else
    echo -e "${RED}synth_netlist.v not found in ${SRC_DIR}. Run synthesis first.${RESET}"
  fi
fi

# -------------------------
# STEP 6: Run full OpenLane flow (RTL->GDSII)
# -------------------------
step "Step 6: Run full OpenLane flow (RTL -> GDSII)"

RUN_CMD="./flow.tcl -design ${DESIGN} -tag ${TAG} -overwrite"
if $DRY_RUN; then
  echo "Dry-run: would execute: ${RUN_CMD} inside ${OPENLANE_REPO}"
else
  echo "Starting OpenLane flow. This runs inside the OpenLane container (make mount)."
  echo "If you are already inside the container run these commands:"
  echo "  cd /openlane"
  echo "  ${RUN_CMD}"
  echo
  echo "Or run from host to open a container and start interactive session:"
  echo "  cd \"${OPENLANE_REPO}\" && make mount"
  echo
  echo -e "${YELLOW}Note: OpenLane will write results to ${DESIGN_DIR}/runs/${TAG}/results${RESET}"
fi

# -------------------------
# STEP 7: Running individual flow stages (examples)
# -------------------------
step "Step 7: Running individual flow stages (examples)"

cat <<'EOF'
# Examples (run inside container /openlane):
# Synthesis only:
#   ./flow.tcl -design DESIGN -tag TAG -from synthesis -to synthesis
# Floorplan only:
#   ./flow.tcl -design DESIGN -tag TAG -from floorplan -to floorplan
# Placement only:
#   ./flow.tcl -design DESIGN -tag TAG -from placement -to placement
# CTS:
#   ./flow.tcl -design DESIGN -tag TAG -from cts -to cts
# Routing:
#   ./flow.tcl -design DESIGN -tag TAG -from routing -to routing
EOF

# -------------------------
# STEP 8: Collect and archive results (host)
# -------------------------
step "Step 8: Archive results and extract key artifacts (host)"

if $DRY_RUN; then
  echo "Dry-run: would copy results from ${DESIGN_DIR}/runs/${TAG}/results to ${HOME}/systolic_array_results and create tarball."
else
  SRC_RESULTS="${DESIGN_DIR}/runs/${TAG}/results"
  if [[ -d "${SRC_RESULTS}" ]]; then
    DEST="${HOME}/systolic_array_results/${DESIGN}_${TAG}"
    run "mkdir -p \"${DEST}\""
    run "cp -v \"${SRC_RESULTS}/final/gds/${DESIGN}.gds\" \"${DEST}/\" || true"
    run "cp -v \"${SRC_RESULTS}/final/verilog/gl/${DESIGN}.v\" \"${DEST}/\" || true"
    run "cp -v \"${SRC_RESULTS}/reports/final_summary_report.csv\" \"${DEST}/\" || true"
    run "cp -rv \"${SRC_RESULTS}/logs\" \"${DEST}/\" || true"
    run "tar -C \"${HOME}/systolic_array_results\" -czf \"${DEST}.tar.gz\" \"${DESIGN}_${TAG}\" || true"
    echo -e "${GREEN}Archived results to ${DEST}.tar.gz${RESET}"
  else
    echo -e "${YELLOW}Results directory not found: ${SRC_RESULTS}. Run OpenLane flow first.${RESET}"
  fi
fi

# -------------------------
# STEP 9: Helpful reminders & debug commands
# -------------------------
step "Step 9: Helpful tips & debug commands"

cat <<EOF
- To view the GDS locally use: klayout /path/to/final/gds/<design>.gds
- To tail the OpenLane logs: tail -f ${DESIGN_DIR}/runs/${TAG}/logs/openlane.log
- To check warnings/errors: grep -i "error" ${DESIGN_DIR}/runs/${TAG}/logs/openlane.log
- To run DRC/LVS use magic/netgen inside the container (see OpenLane docs)
EOF

echo -e "${GREEN}${BOLD}Script finished (or dry-run summary). Log: ${logfile}${RESET}"
