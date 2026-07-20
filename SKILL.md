---
name: apple-notes
description: Use this skill when the task involves reading, searching, creating, editing, organizing, or moving Apple Notes on macOS. This includes finding notes, creating folders, moving notes into folders, appending structured content to an existing note, and writing well-formatted content into Apple Notes without re-testing multiple access methods.
homepage: https://github.com/lishix520/apple-notes-skill
metadata: {"openclaw":{"emoji":"📝","homepage":"https://github.com/lishix520/apple-notes-skill","os":["darwin"],"requires":{"bins":["osascript"]}}}
---

# Apple Notes Skill (v0.2.0)

Use this skill to automate Apple Notes on macOS through the provided helper script `notes.sh`.

## Agent Execution Rules

1. **Invoke Wrapper Script**: Always run commands via `./notes.sh` (or the local path to it). Do not write custom raw AppleScript.
2. **Search Before Creating**: Search note titles first to check if a note already exists.
3. **Append Over Overwrite**: Prefer appending new sections to existing notes rather than overwriting their entire body.
4. **Destructive Actions**: Always verify the note title and folder name before moving or deleting. Never delete a note without explicit confirmation.
5. **Escape Inputs**: Apple Notes bodies are HTML. Wrap plain text in `<div>` or `<p>` blocks when writing/appending. Escaping special characters is handled by the script.

---

## Command Reference (CRUD & Query)

The wrapper script `notes.sh` accepts the following arguments:

### 1. Create Operations
*   **Create Note**:
    ```bash
    ./notes.sh create-note "Note Title" "Folder Name" "<h1>Title</h1><div>HTML body content</div>"
    ```
    *Creates a new note. The folder is automatically created if it does not exist.*
*   **Create Folder**:
    ```bash
    ./notes.sh create-folder "Folder Name"
    ```
    *Creates a folder if it does not exist.*

### 2. Read Operations
*   **Read Note Body**:
    ```bash
    ./notes.sh read-note "Note Title" ["Folder Name"]
    ```
    *Returns the HTML body of the note. Specify the folder for faster lookup and resolution of duplicate titles. If folder is omitted, it searches globally.*

### 3. Update Operations
*   **Append Note**:
    ```bash
    ./notes.sh append-note "Note Title" "Folder Name" "<div>Appended HTML content</div>"
    ```
    *Appends HTML content to the end of the existing note.*

### 4. Delete & Move Operations
*   **Move Note**:
    ```bash
    ./notes.sh move-note "Note Title" "Source Folder" "Destination Folder"
    ```
    *Moves a note between folders. Destination folder must exist.*
*   **Delete Note**:
    ```bash
    ./notes.sh delete-note "Note Title" "Folder Name"
    ```
    *Deletes the note (moves to Recently Deleted).*

### 5. Query & Info Operations
*   **Search Notes Globally**:
    ```bash
    ./notes.sh search-notes "QueryText"
    ```
    *Lists matching notes across all folders as tab-separated: `<Folder>\t<Title>`.*
*   **List Folders**:
    ```bash
    ./notes.sh list-folders
    ```
    *Lists all folder names, one per line.*
*   **List Notes in Folder**:
    ```bash
    ./notes.sh list-notes "Folder Name"
    ```
    *Lists notes inside a folder as tab-separated: `<Title>\t<Modification Date>`.*
*   **Get Modification Date**:
    ```bash
    ./notes.sh get-date "Note Title" "Folder Name"
    ```
    *Returns the modification date string of the note.*
*   **Count All Notes**:
    ```bash
    ./notes.sh count-all
    ```
    *Returns the total number of notes in the app.*
*   **Count Notes in Folder**:
    ```bash
    ./notes.sh count-folder "Folder Name"
    ```
    *Returns the total number of notes in the specified folder.*

---

## Output Behavior & Gotchas

*   **HTML format**: Apple Notes bodies return HTML tags (e.g. `<div>`, `<br>`). When reading notes, strip or parse tags to interpret text structure.
*   **Error Handling**: If a command fails (e.g., folder not found), the script outputs to stderr and returns a non-zero code. Read the stderr output to diagnose and adjust arguments.
*   **Ambiguity**: If multiple notes share the same title, prioritize specifying folder names to narrow down the target.
