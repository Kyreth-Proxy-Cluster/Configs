#!/usr/bin/env bash
# ==============================================================================
# Mihomo Rules Compiler
# Compiles rule-sets specifically for the Mihomo core.
# ==============================================================================

set -Eeuo pipefail

# ------------------------------------------------------------------------------
# 1. Configuration and Paths
# ------------------------------------------------------------------------------
# The output directory is passed as the first argument by the orchestrator
OUTPUT_DIR="$1"
if [[ -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <output_directory>" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_SRC_DIR="${SCRIPT_DIR}/rule-sets"

# ------------------------------------------------------------------------------
# 2. Helper Functions
# ------------------------------------------------------------------------------
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

# Extract the 'behavior' parameter from meta.yaml
get_rule_behavior() {
    local meta_file="$1"
    yq -r '.behavior' "$meta_file"
}

# ------------------------------------------------------------------------------
# 3. Compilation Logic
# ------------------------------------------------------------------------------

# Compile a single rule for Mihomo
compile_rule() {
    local meta_file="$1"
    local behavior
    behavior="$(get_rule_behavior "$meta_file")"

    local rule_dir
    rule_dir="$(dirname "$meta_file")"

    # Extract category (e.g., geosite) and rule name
    local category
    category="$(basename "$(dirname "$rule_dir")")"
    
    local rule_name
    rule_name="$(basename "$rule_dir")"

    local dest_dir="${OUTPUT_DIR}/${category}"
    local dest_mrs="${dest_dir}/${rule_name}.mrs"
    local dest_list="${dest_dir}/${rule_name}.list"
    local rule_list_file="${rule_dir}/rule.list"

    mkdir -p "$dest_dir"

    log_info "Compiling Mihomo [${behavior}] ${category}/${rule_name}..."

    # Create a temporary YAML file for the mihomo converter
    local tmp_file
    tmp_file="$(mktemp --suffix=.yaml)"

    {
        echo "payload:"
        # Add indentation for a valid YAML format
        sed 's/^/  - /' "$rule_list_file"
    } > "$tmp_file"

    # Convert rules to the .mrs format
    mihomo convert-ruleset "$behavior" yaml "$tmp_file" "$dest_mrs"

    # Copy the original .list file
    cp "$rule_list_file" "$dest_list"

    # Clean up the temporary file
    rm -f "$tmp_file"
}

# Find and process all rules
process_all_rules() {
    log_info "Searching for rules to compile..."
    local count=0

    # Search for all meta.yaml files in the source rule-sets directory
    while IFS= read -r -d '' meta_file; do
        compile_rule "$meta_file"
        ((count++))
    done < <(find "$RULES_SRC_DIR" -name "meta.yaml" -print0)

    if [[ $count -eq 0 ]]; then
        log_error "No rules found in ${RULES_SRC_DIR}!"
        exit 1
    fi

    log_info "Successfully compiled rules: ${count}"
}

# Ensure no meta.yaml files are accidentally left in the output folder
cleanup_artifacts() {
    log_info "Cleaning up artifacts (removing meta.yaml)..."
    find "$OUTPUT_DIR" -name "meta.yaml" -type f -delete
}

# ------------------------------------------------------------------------------
# 4. Entry Point
# ------------------------------------------------------------------------------
main() {
    log_info "Starting Mihomo rules compilation..."
    
    process_all_rules
    cleanup_artifacts
    
    log_info "Mihomo compilation completed successfully!"
}

main "$@"