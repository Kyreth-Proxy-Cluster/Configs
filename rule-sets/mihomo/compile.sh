#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

BUILD_DIR="build"
OUTPUT_DIR="${BUILD_DIR}/rule-sets"


find_targets() {
    find . -name meta.yaml -print0
}


parse_meta() {
    local meta_path="$1"
    yq -r '.behavior' "$meta_path"
}


compile_rule() {
    local meta_path="$1"
    local behavior="$2"

    local rule_dir
    local behavior
    local list
    local category
    local name
    local dest_dir
    local dest_file
    local tmp


    rule_dir="$(dirname "$meta_path")"

    category="$(basename "$(dirname "$rule_dir")")"
    name="$(basename "$rule_dir")"

    dest_dir="${OUTPUT_DIR}/${category}"
    dest_file="${dest_dir}/${name}.mrs"

    mkdir -p "$dest_dir"

    echo "[${behavior}] ${category}/${name}"

    tmp="$(mktemp --suffix=.yaml)"

    {
        echo "payload:"
        sed 's/^/  - /' "${rule_dir}/rule.list"
    } > "$tmp"

    mihomo convert-ruleset \
        "$behavior" \
        yaml \
        "$tmp" \
        "$dest_file"


    rm -f "$tmp"
}


archive_rules() {
    local archive_name="mihomo.zip"
    cd "$BUILD_DIR" && zip -qr "../${archive_name}" rule-sets
    echo "Archive created: ${archive_name}"
}


main() {

    rm -rf "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"


    while IFS= read -r -d '' meta_path; do
        behavior="$(parse_meta "$meta_path")"

        compile_rule "$meta_path" "$behavior"

    done < <(find_targets)


    archive_rules
}


main "$@"