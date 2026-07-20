#!/usr/bin/env bash
# Smoke Tests (Read-Only) for Apple Notes Skill

set -euo pipefail

SCRIPT="./notes.sh"

echo "=== Running Read-Only Smoke Tests ==="

echo "1. Testing list-folders..."
$SCRIPT list-folders >/dev/null
echo "✓ list-folders completed successfully"

echo "2. Testing count-all..."
COUNT=$($SCRIPT count-all)
echo "✓ count-all returned: $COUNT"

echo "3. Testing search-notes with impossible query..."
$SCRIPT search-notes "___nonexistent_dummy_note_search___" >/dev/null
echo "✓ search-notes completed successfully (empty result)"

echo "4. Testing list-folders with --json..."
$SCRIPT --json list-folders >/dev/null
echo "✓ list-folders --json completed successfully"

echo "=== All Read-Only Smoke Tests Passed! ==="
