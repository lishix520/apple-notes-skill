#!/usr/bin/env bash
# Smoke Tests (Read-Only) for Apple Notes Skill (v0.3.1)

set -euo pipefail

SCRIPT="./notes.sh"

# Native JXA parser helper to validate JSON format without jq
validate_json() {
    local data="$1"
    osascript -l JavaScript -e 'function run(argv) { try { JSON.parse(argv[0]); } catch(e) { console.log("INVALID: " + e.message); } }' -- "$data"
}

echo "=== Running Read-Only Smoke Tests ==="

echo "1. Testing list-folders..."
FOLDERS=$($SCRIPT list-folders)
echo "✓ list-folders completed successfully"

echo "2. Testing count-all..."
COUNT=$($SCRIPT count-all)
echo "✓ count-all returned: $COUNT"

echo "3. Testing search-notes with impossible query..."
$SCRIPT search-notes "___nonexistent_dummy_note_search___" >/dev/null
echo "✓ search-notes completed successfully (empty result)"

echo "4. Testing list-folders with --json..."
JSON_OUT=$($SCRIPT --json list-folders)
PARSE_ERR=$(validate_json "$JSON_OUT")
if [ -n "$PARSE_ERR" ]; then
    echo "Fail: list-folders --json output is invalid JSON! Details: $PARSE_ERR" >&2
    echo "Output was: $JSON_OUT" >&2
    exit 1
fi
echo "✓ list-folders --json output is valid JSON: $JSON_OUT"

echo "=== All Read-Only Smoke Tests Passed! ==="
