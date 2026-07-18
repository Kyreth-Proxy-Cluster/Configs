#!/usr/bin/env bash
# ==============================================================================
# Top-level Rules Compiler Orchestrator
# Manages the compilation process for multiple proxy cores.
# ==============================================================================

set -Eeuo pipefail

# ------------------------------------------------------------------------------
# 1. Configuration
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"

# List of cores to compile. 
# Add 'stash', 'singbox', 'xray' to this array in the future.
CORES=("mihomo")

# ------------------------------------------------------------------------------
# 2. Helper Functions
# ------------------------------------------------------------------------------
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

# ------------------------------------------------------------------------------
# 3. Core Functions
# ------------------------------------------------------------------------------

# Clean up and create the main distribution directory
setup_dist() {
    log_info "Setting up distribution directory..."
    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"
}

# Compile rules for a specific core
compile_core() {
    local core_name="$1"
    local core_script="${SCRIPT_DIR}/${core_name}/compile.sh"
    local core_output_dir="${DIST_DIR}/${core_name}"

    if [[ ! -f "$core_script" ]]; then
        log_error "Compiler script not found for core: ${core_name} (${core_script})"
        return 1
    fi

    log_info "Starting compilation for core: ${core_name}..."
    
    # Create the specific output directory for this core
    mkdir -p "$core_output_dir"

    # Execute the core-specific compiler, passing the output directory as an argument
    bash "$core_script" "$core_output_dir"
    
    log_info "Finished compilation for core: ${core_name}"
}

# ------------------------------------------------------------------------------
# 4. Entry Point
# ------------------------------------------------------------------------------
main() {
    log_info "Starting multi-core rules compilation..."
    
    setup_dist
    
    for core in "${CORES[@]}"; do
        compile_core "$core"
    done
    
    log_info "All cores compiled successfully! Output is in: ${DIST_DIR}"
}

main "$@"