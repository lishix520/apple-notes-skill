#!/usr/bin/env bash
# Integration Tests for Apple Notes Skill (v0.3.1)

set -euo pipefail

if [ "${APPLE_NOTES_SKILL_RUN_INTEGRATION_TESTS:-0}" != "1" ]; then
    echo "Skipping integration tests. To run them, set APPLE_NOTES_SKILL_RUN_INTEGRATION_TESTS=1"
    exit 0
fi

SCRIPT="./notes.sh"
TEST_RUN_ID="$(date +%s)-$$"
TEST_FOLDER="__apple_notes_skill_test_${TEST_RUN_ID}"
TEST_DEST_FOLDER="${TEST_FOLDER}_dest"
TEST_NOTE="__test_note_${TEST_RUN_ID}"

# Native JXA parser helper to validate JSON format without jq
validate_json() {
    local data="$1"
    osascript -l JavaScript -e 'function run(argv) { try { JSON.parse(argv[0]); } catch(e) { console.log("INVALID: " + e.message); } }' -- "$data"
}

cleanup() {
    echo "=== Cleaning up test resources ==="
    # Try deleting the note by title just in case
    $SCRIPT delete-note-title "$TEST_NOTE" "$TEST_FOLDER" --confirm 2>/dev/null || true
    $SCRIPT delete-note-title "$TEST_NOTE" "$TEST_DEST_FOLDER" --confirm 2>/dev/null || true
    
    # Try deleting folders
    $SCRIPT delete-folder "$TEST_FOLDER" --confirm 2>/dev/null || true
    $SCRIPT delete-folder "$TEST_DEST_FOLDER" --confirm 2>/dev/null || true
    echo "Cleanup finished."
}
trap cleanup EXIT

echo "=== Running Integration Tests ==="

# 1. Create folder
echo "1. Creating folder '$TEST_FOLDER'..."
CREATE_FOLDER_OUT=$($SCRIPT --json create-folder "$TEST_FOLDER")
PARSE_ERR=$(validate_json "$CREATE_FOLDER_OUT")
if [ -n "$PARSE_ERR" ]; then
    echo "Fail: create-folder --json output is invalid JSON! Details: $PARSE_ERR" >&2
    exit 1
fi
echo "✓ Folder created successfully. Output: $CREATE_FOLDER_OUT"

# 2. Create note (text) with escaping test
echo "2. Creating text note '$TEST_NOTE'..."
CREATE_NOTE_OUT=$($SCRIPT --json create-note-text "$TEST_NOTE" "$TEST_FOLDER" 'Initial text content: & < >')
PARSE_ERR=$(validate_json "$CREATE_NOTE_OUT")
if [ -n "$PARSE_ERR" ]; then
    echo "Fail: create-note-text --json output is invalid JSON! Details: $PARSE_ERR" >&2
    exit 1
fi
echo "✓ Note created. Output: $CREATE_NOTE_OUT"

# 3. List notes and get ID and date
echo "3. Listing notes and extracting ID..."
LIST_OUT=$($SCRIPT --json list-notes "$TEST_FOLDER")
PARSE_ERR=$(validate_json "$LIST_OUT")
if [ -n "$PARSE_ERR" ]; then
    echo "Fail: list-notes --json output is invalid JSON! Details: $PARSE_ERR" >&2
    exit 1
fi
echo "List output: $LIST_OUT"

NOTE_ID=$(echo "$LIST_OUT" | grep -o 'x-coredata://[^"]*' | head -n 1)
if [ -z "$NOTE_ID" ]; then
    echo "Failed to extract note ID from list output!" >&2
    exit 1
fi
echo "✓ Extracted note ID: $NOTE_ID"

DATE_VAL=$(echo "$LIST_OUT" | grep -o '"modified_at":"[^"]*' | head -n 1 | cut -d'"' -f4)
if [ -z "$DATE_VAL" ]; then
    echo "Failed to extract modification date from list output!" >&2
    exit 1
fi
echo "✓ Extracted modification date: $DATE_VAL"

# 4. Read note by ID
echo "4. Reading note by ID..."
READ_OUT=$($SCRIPT --json read-note-id "$NOTE_ID")
PARSE_ERR=$(validate_json "$READ_OUT")
if [ -n "$PARSE_ERR" ]; then
    echo "Fail: read-note-id --json output is invalid JSON! Details: $PARSE_ERR" >&2
    exit 1
fi
BODY=$(echo "$READ_OUT" | grep -o '"body":"[^"]*' | head -n 1 | cut -d'"' -f4)
echo "✓ Body output: $BODY"
if [[ "$BODY" != *"&amp"* ]] || [[ "$BODY" != *"&lt"* ]] || [[ "$BODY" != *"&gt"* ]]; then
    echo "HTML escaping verification failed!" >&2
    exit 1
fi

# 5. Append html content by ID with Concurrency locks
echo "5. Testing optimistic concurrency append locks..."
# First, try to append with a mismatched date. It must fail with code 7.
echo "   a. Trying to append with mismatched date (expected conflict)..."
if $SCRIPT --json --if-modified-at "2000-01-01T00:00:00.000Z" append-note-html "$NOTE_ID" '<div>Conflict check</div>' 2>/dev/null; then
    echo "Conflict check failed: append succeeded with a wrong date!" >&2
    exit 1
else
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 7 ]; then
        echo "Conflict check failed: returned code $EXIT_CODE, expected 7!" >&2
        exit 1
    fi
    echo "   ✓ Mismatched date successfully blocked with code 7 (Conflict)"
fi

# Next, append with the correct date. It must succeed.
echo "   b. Appending with correct date..."
$SCRIPT --json --if-modified-at "$DATE_VAL" append-note-html "$NOTE_ID" '<div>Appended content.</div>'
echo "   ✓ Append succeeded"

# 6. Test confirmation safeguard for move note
echo "6. Testing move note confirmation safeguard..."
ERR_OUT=""
if $SCRIPT --json move-note-id "$NOTE_ID" "$TEST_DEST_FOLDER" 2>tmp_err.json; then
    echo "Safeguard failed: move succeeded without --confirm!" >&2
    rm -f tmp_err.json
    exit 1
else
    EXIT_CODE=$?
    ERR_OUT=$(cat tmp_err.json)
    rm -f tmp_err.json
    if [ "$EXIT_CODE" -ne 5 ]; then
        echo "Safeguard failed: move without --confirm returned code $EXIT_CODE, expected 5!" >&2
        exit 1
    fi
    PARSE_ERR=$(validate_json "$ERR_OUT")
    if [ -n "$PARSE_ERR" ]; then
        echo "Fail: move safeguard JSON error output is invalid! Details: $PARSE_ERR" >&2
        echo "Error payload was: $ERR_OUT" >&2
        exit 1
    fi
    echo "✓ Move note safeguard passed (refused execution with code 5, valid JSON error payload)"
fi

# 7. Create destination folder and execute confirmed move
echo "7. Creating destination folder and executing confirmed move..."
$SCRIPT --json create-folder "$TEST_DEST_FOLDER" >/dev/null
$SCRIPT --json move-note-id "$NOTE_ID" "$TEST_DEST_FOLDER" --confirm >/dev/null
echo "✓ Note moved successfully"

# 8. Verify note has moved
echo "8. Verifying note location..."
COUNT_SRC=$($SCRIPT count-folder "$TEST_FOLDER")
COUNT_DEST=$($SCRIPT count-folder "$TEST_DEST_FOLDER")
if [ "$COUNT_SRC" -ne 0 ] || [ "$COUNT_DEST" -ne 1 ]; then
    echo "Verification of move failed (source count: $COUNT_SRC, dest count: $COUNT_DEST)!" >&2
    exit 1
fi
echo "✓ Move verified successfully"

# 9. Test confirmation safeguard for delete note
echo "9. Testing delete note confirmation safeguard..."
if $SCRIPT --json delete-note-id "$NOTE_ID" 2>tmp_err.json; then
    echo "Safeguard failed: delete succeeded without --confirm!" >&2
    rm -f tmp_err.json
    exit 1
else
    EXIT_CODE=$?
    ERR_OUT=$(cat tmp_err.json)
    rm -f tmp_err.json
    if [ "$EXIT_CODE" -ne 5 ]; then
        echo "Safeguard failed: delete without --confirm returned code $EXIT_CODE, expected 5!" >&2
        exit 1
    fi
    PARSE_ERR=$(validate_json "$ERR_OUT")
    if [ -n "$PARSE_ERR" ]; then
        echo "Fail: delete safeguard JSON error output is invalid! Details: $PARSE_ERR" >&2
        exit 1
    fi
    echo "✓ Delete note safeguard passed (refused execution with code 5, valid JSON error payload)"
fi

# 10. Execute confirmed delete
echo "10. Deleting note with confirmation..."
$SCRIPT --json delete-note-id "$NOTE_ID" --confirm >/dev/null
COUNT_AFTER_DELETE=$($SCRIPT count-folder "$TEST_DEST_FOLDER")
if [ "$COUNT_AFTER_DELETE" -ne 0 ]; then
    echo "Note deletion failed!" >&2
    exit 1
fi
echo "✓ Note deleted successfully"

# 11. Test parameter boundary safeguard via --
echo "11. Testing argument parsing escape via -- ..."
# Create note whose body looks like an option (e.g. "--confirm")
$SCRIPT --json create-note-text "OptionBoundaryNote" "$TEST_FOLDER" -- "--confirm" >/dev/null
echo "✓ Created note with body '--confirm' successfully using boundary separator --"

# Cleanup option boundary note before exiting
$SCRIPT --json delete-note-title "OptionBoundaryNote" "$TEST_FOLDER" --confirm >/dev/null

echo "=== All Integration Tests Passed Successfully! ==="
