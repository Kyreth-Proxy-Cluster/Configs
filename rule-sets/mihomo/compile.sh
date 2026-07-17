#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

CORE_NAME="${CORE_NAME:-mihomo}"
MCM_BIN="${MCM_BIN:-mihomo}"

BUILD_DIR="build"
OUTPUT_DIR="${BUILD_DIR}/rule-sets"

rm -rf "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

find . -name meta.yaml -print0 | while IFS= read -r -d '' META; do

    RULE_DIR="$(dirname "$META")"

    CATEGORY="$(basename "$(dirname "$RULE_DIR")")"
    NAME="$(basename "$RULE_DIR")"

    BEHAVIOR="$(yq -r '.behavior' "$META")"

    LIST="${RULE_DIR}/rule.list"

    DEST_DIR="${OUTPUT_DIR}/${CATEGORY}"
    DEST_FILE="${DEST_DIR}/${NAME}.mrs"

    mkdir -p "$DEST_DIR"

    TMP="$(mktemp --suffix=.yaml)"

    {
        echo "payload:"
        sed 's/^/  - /' "$LIST"
    } > "$TMP"

    echo "[${BEHAVIOR}] ${CATEGORY}/${NAME}"

    "$MCM_BIN" convert-ruleset \
        "$BEHAVIOR" \
        yaml \
        "$TMP" \
        "$DEST_FILE"

    rm "$TMP"

done

(
    cd "$BUILD_DIR"
    zip -r "../${CORE_NAME}.zip" rulesets >/dev/null
)

echo
echo "Archive created:"
echo "${CORE_NAME}.zip"
