#!/bin/bash
set -e

SCRIPT="./notes.sh"

echo "=== 1. Listing folders ==="
$SCRIPT list-folders

echo ""
echo "=== 2. Creating folder 'TestFolder_Temp' ==="
$SCRIPT create-folder "TestFolder_Temp"

echo ""
echo "=== 3. Creating note 'TestNote_Temp' inside 'TestFolder_Temp' ==="
$SCRIPT create-note "TestNote_Temp" "TestFolder_Temp" "<h1>Title</h1><div>Initial body content.</div>"

echo ""
echo "=== 4. Reading note 'TestNote_Temp' inside 'TestFolder_Temp' ==="
BODY=$($SCRIPT read-note "TestNote_Temp" "TestFolder_Temp")
echo "Body output: $BODY"

echo ""
echo "=== 5. Appending HTML content to note ==="
$SCRIPT append-note "TestNote_Temp" "TestFolder_Temp" "<div>Appended content.</div>"

echo ""
echo "=== 6. Reading note again to verify append ==="
BODY_NEW=$($SCRIPT read-note "TestNote_Temp" "TestFolder_Temp")
echo "New Body output: $BODY_NEW"

echo ""
echo "=== 7. Getting modification date of note ==="
$SCRIPT get-date "TestNote_Temp" "TestFolder_Temp"

echo ""
echo "=== 8. Counting notes in 'TestFolder_Temp' ==="
$SCRIPT count-folder "TestFolder_Temp"

echo ""
echo "=== 9. Searching globally for 'TestNote_Temp' ==="
$SCRIPT search-notes "TestNote_Temp"

echo ""
echo "=== 10. Moving note to 'TestFolder_Temp_2' ==="
$SCRIPT create-folder "TestFolder_Temp_2"
$SCRIPT move-note "TestNote_Temp" "TestFolder_Temp" "TestFolder_Temp_2"

echo ""
echo "=== 11. Listing notes in 'TestFolder_Temp_2' ==="
$SCRIPT list-notes "TestFolder_Temp_2"

echo ""
echo "=== 12. Deleting note 'TestNote_Temp' from 'TestFolder_Temp_2' ==="
$SCRIPT delete-note "TestNote_Temp" "TestFolder_Temp_2"

echo ""
echo "=== 13. Getting count of notes in 'TestFolder_Temp_2' (should be 0) ==="
$SCRIPT count-folder "TestFolder_Temp_2"

echo ""
echo "=== 14. Global count of notes ==="
$SCRIPT count-all

echo ""
echo "Verification successfully completed!"
