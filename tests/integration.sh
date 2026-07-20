#!/usr/bin/env bash
# Integration Tests for Apple Notes Skill

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
$SCRIPT create-folder "$TEST_FOLDER"

# 2. Create note (text) with escaping test
echo "2. Creating text note '$TEST_NOTE'..."
$SCRIPT create-note-text "$TEST_NOTE" "$TEST_FOLDER" 'Initial text content with special chars: & < >'

# 3. List notes and get ID
echo "3. Listing notes and extracting ID..."
LIST_OUT=$($SCRIPT --json list-notes "$TEST_FOLDER")
echo "List output: $LIST_OUT"
NOTE_ID=$(echo "$LIST_OUT" | grep -o 'x-coredata://[^"]*' | head -n 1)
if [ -z "$NOTE_ID" ]; then
    echo "Failed to extract note ID from list output!" >&2
    exit 1
fi
echo "✓ Extracted note ID: $NOTE_ID"

# 4. Read note by ID
echo "4. Reading note by ID..."
BODY=$($SCRIPT read-note-id "$NOTE_ID")
echo "✓ Body output: $BODY"
if [[ "$BODY" != *"special chars:"* ]]; then
    echo "Text verification failed!" >&2
    exit 1
fi

# 5. Append html content by ID
echo "5. Appending HTML content..."
$SCRIPT append-note-html "$NOTE_ID" '<div>Appended HTML content.</div>'
NEW_BODY=$($SCRIPT read-note-id "$NOTE_ID")
echo "✓ New body output: $NEW_BODY"
if [[ "$NEW_BODY" != *"Appended HTML content."* ]]; then
    echo "Append html verification failed!" >&2
    exit 1
fi

# 6. Test confirmation safeguard for move
echo "6. Testing move note confirmation safeguard..."
if $SCRIPT move-note-id "$NOTE_ID" "$TEST_DEST_FOLDER" 2>/dev/null; then
    echo "Safeguard failed: move succeeded without --confirm!" >&2
    exit 1
else
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 5 ]; then
        echo "Safeguard failed: move without --confirm returned code $EXIT_CODE, expected 5!" >&2
        exit 1
    fi
    echo "✓ Move note safeguard passed (refused execution with exit code 5)"
fi

# 7. Create destination folder and execute confirmed move
echo "7. Creating destination folder and executing confirmed move..."
$SCRIPT create-folder "$TEST_DEST_FOLDER"
$SCRIPT move-note-id "$NOTE_ID" "$TEST_DEST_FOLDER" --confirm
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

# 9. Test confirmation safeguard for delete
echo "9. Testing delete note confirmation safeguard..."
if $SCRIPT delete-note-id "$NOTE_ID" 2>/dev/null; then
    echo "Safeguard failed: delete succeeded without --confirm!" >&2
    exit 1
else
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 5 ]; then
        echo "Safeguard failed: delete without --confirm returned code $EXIT_CODE, expected 5!" >&2
        exit 1
    fi
    echo "✓ Delete note safeguard passed (refused execution with exit code 5)"
fi

# 10. Execute confirmed delete
echo "10. Deleting note with confirmation..."
$SCRIPT delete-note-id "$NOTE_ID" --confirm
COUNT_AFTER_DELETE=$($SCRIPT count-folder "$TEST_DEST_FOLDER")
if [ "$COUNT_AFTER_DELETE" -ne 0 ]; then
    echo "Note deletion failed!" >&2
    exit 1
fi
echo "✓ Note deleted successfully"

echo "=== All Integration Tests Passed Successfully! ==="
