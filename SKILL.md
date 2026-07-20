---
name: apple-notes
description: Use this skill when the task involves reading, searching, creating, editing, organizing, or moving Apple Notes on macOS. This includes finding notes, creating folders, moving notes into folders, appending structured content to an existing note, and writing well-formatted content into Apple Notes without re-testing multiple access methods.
homepage: https://github.com/lishix520/apple-notes-skill
metadata: {"openclaw":{"emoji":"📝","homepage":"https://github.com/lishix520/apple-notes-skill","os":["darwin"],"requires":{"bins":["osascript"]}}}
---

# Apple Notes Skill (v0.3.0)

Use this skill to safely and robustly automate Apple Notes on macOS using the unified native wrapper script `./notes.sh`.

## 7 Absolute Rules

1. **Only use Wrapper**: Always invoke `./notes.sh`. Never write or execute custom raw AppleScript blocks.
2. **Search Before Creating**: Always search note titles first using `search-notes` to check if a note already exists.
3. **Use ID-based Targets**: For read, update, delete, and move operations, always use the ID-based commands (e.g., `read-note-id`).
4. **Enforce CLI Confirmation**: Always append `--confirm` to destructive commands (`move-note-id`, `delete-note-id`, `delete-folder`) only *after* obtaining explicit user confirmation.
5. **Format Safety**: Use `*-text` commands for safety-escaped plain text, and `*-html` commands only for trusted HTML bodies.
6. **Handle Exit Codes**: Check exit status to handle errors programmatically (e.g., Code 4 for Ambiguity, Code 5 for Confirmation Required).
7. **No Silence**: Never suppress command errors; report the exact command output when a command fails.

---

## Action Matrix

| Intent | Command | Target Arguments | Pre-conditions |
| :--- | :--- | :--- | :--- |
| **Search Notes** | `search-notes` | `<query>` | None |
| **List Folder Notes** | `list-notes` | `<folder>` | None |
| **List Folders** | `list-folders` | None | None |
| **Read note by ID** | `read-note-id` | `<note_id>` | Use `search-notes`/`list-notes` first to get ID |
| **Read note by Title** | `read-note-title`| `<title> [folder]` | Use only if note title is unique |
| **Create Text Note** | `create-note-text`| `<title> <folder> <plain_text>` | Search first to prevent duplicate titles |
| **Create HTML Note** | `create-note-html`| `<title> <folder> <body_html>` | Search first to prevent duplicate titles |
| **Create Folder** | `create-folder` | `<folder>` | None |
| **Append Text** | `append-note-text`| `<note_id> <plain_text>` | Search first to get note ID |
| **Append HTML** | `append-note-html`| `<note_id> <body_html>` | Search first to get note ID |
| **Move Note** | `move-note-id` | `<note_id> <dest_folder> --confirm` | User confirmation required |
| **Delete Note** | `delete-note-id` | `<note_id> --confirm` | User confirmation required |
| **Delete Folder** | `delete-folder` | `<folder> --confirm` | User confirmation required |

*Add `--json` globally to receive clean, parseable JSON results.*

---

## Exit Status Matrix

- **`0`**: Success
- **`2`**: Parameter/Syntax error (usage mismatch)
- **`3`**: Resource Not Found (folder or note ID not found)
- **`4`**: Ambiguity (multiple note matches found for title-based lookups)
- **`5`**: Confirmation Required (refused destructive command because `--confirm` was missing)
- **`6`**: Native AppleScript/JXA execution failure

---

## Usage Examples

### 1. Retrieve a note's ID and Read its Content
```bash
./notes.sh --json search-notes "Daily Log"
# Parser finds note ID "x-coredata://..."
./notes.sh read-note-id "x-coredata://..."
```

### 2. Create and Append content safely
```bash
./notes.sh create-note-text "Project Alpha" "Inbox" "Initial project description."
# Append dated updates safely
./notes.sh append-note-text "x-coredata://..." $'\n- Update 2026-07-20: Done.'
```

### 3. Safely Delete a note (shows confirmation safeguard)
```bash
# First try without confirm:
./notes.sh delete-note-id "x-coredata://..."
# Output: Refusing destructive action... Exit code: 5.
# Ask user, then run with --confirm:
./notes.sh delete-note-id "x-coredata://..." --confirm
```

For complete CLI helper details, run `./notes.sh --help`.
