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

# Determine behavior based on category folder name
get_rule_behavior() {
  local category="$1"
  case "$category" in
    geoip)
      echo "ipcidr"
      ;;
    geosite)
      echo "domain"
      ;;
    packages|processes|*)
      echo "classical"
      ;;
  esac
}

# ------------------------------------------------------------------------------
# 3. Compilation Logic
# ------------------------------------------------------------------------------
# Compile a single rule for Mihomo
compile_rule() {
    local meta_file="$1"

    local rule_dir
    rule_dir="$(dirname "$meta_file")"

    # Extract category (e.g., geosite) and rule name
    local category
    category="$(basename "$(dirname "$rule_dir")")"
    
    local rule_name
    rule_name="$(basename "$rule_dir")"
    
    local behavior
    behavior="$(get_rule_behavior "$category")"

    local dest_dir="${OUTPUT_DIR}/${category}"
    local dest_list="${dest_dir}/${rule_name}.list"
    local rule_list_file="${rule_dir}/rule.list"

    mkdir -p "$dest_dir"

    log_info "Compiling Mihomo [${behavior}] ${category}/${rule_name}..."

    if [[ "$behavior" == "classical" ]]; then
        local dest_yaml="${dest_dir}/${rule_name}.yaml"

        {
            echo "payload:"
            sed -e 's/\r$//' -e 's/^\(.*\)$/    - "\1"/' "$rule_list_file"
        } > "$dest_yaml"

    else
        local dest_mrs="${dest_dir}/${rule_name}.mrs"
        if ! mihomo convert-ruleset "$behavior" text "$rule_list_file" "$dest_mrs"; then
            log_error "Mihomo converter failed for [${behavior}] ${category}/${rule_name}" 
            rm -f "$dest_mrs"
            return 1
        fi

    fi

    # Copy the original .list file
    cp "$rule_list_file" "$dest_list"
}

# Find and process all rules
process_all_rules() {
    local count=0
    local failed_count=0

    # Search for all meta.yaml files in the source rule-sets directory
    while IFS= read -r -d '' meta_file; do
        if ! compile_rule "$meta_file"; then
            ((failed_count += 1))
        fi
        ((count += 1))
    done < <(find "$RULES_SRC_DIR" -name "meta.yaml" -print0)

    if [[ $count -eq 0 ]]; then
        log_error "No rules found in ${RULES_SRC_DIR}!"
        exit 1
    fi

    if (( failed_count > 0 )); then
        log_error "${failed_count} rule compilation(s) failed."
        exit 1
    fi
}

# Ensure no meta.yaml files are accidentally left in the output folder
cleanup_artifacts() {
    find "$OUTPUT_DIR" -name "meta.yaml" -type f -delete
}

# ------------------------------------------------------------------------------
# 4. Entry Point
# ------------------------------------------------------------------------------
main() {
    process_all_rules
    cleanup_artifacts
}

main "$@"