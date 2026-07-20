---
name: apple-notes
description: Use this skill when the task involves reading, searching, creating, editing, organizing, or moving Apple Notes on macOS. This includes finding notes, creating folders, moving notes into folders, appending structured content to an existing note, and writing well-formatted content into Apple Notes without re-testing multiple access methods.
homepage: https://github.com/lishix520/apple-notes-skill
metadata: {"openclaw":{"emoji":"📝","homepage":"https://github.com/lishix520/apple-notes-skill","os":["darwin"],"requires":{"bins":["osascript"]}}}
---

# Apple Notes Skill (v0.3.1)

Use this skill to safely and robustly automate Apple Notes on macOS using the unified native wrapper script `./notes.sh`.

## 7 Absolute Rules

1. **Only use Wrapper**: Always invoke `./notes.sh`. Never write or execute custom raw AppleScript blocks.
2. **Search Before Creating**: Always search note titles first using `search-notes` to check if a note already exists.
3. **Use ID-based Targets**: For read, update, delete, and move operations, always use the ID-based commands (e.g., `read-note-id`).
4. **Enforce CLI Confirmation**: Always append `--confirm` to destructive commands (`move-note-id`, `delete-note-id`, `delete-folder`) only *after* obtaining explicit user confirmation.
5. **Format Safety**: Use `*-text` commands for safety-escaped plain text, and `*-html` commands only for trusted HTML bodies.
6. **Concurrency Protection**: Guard append operations by passing the last read modification timestamp with `--if-modified-at <ISO-8601>`. Handle Code 7 (Conflict) by re-reading and merging changes.
7. **No Silence**: Never suppress command errors; report the exact stdout/stderr when a command fails.

---

## Command Syntax & Argument Boundary (`--`)

To prevent note titles or bodies from being incorrectly parsed as flags if they happen to start with dashes, always use the double-dash `--` separator:
```bash
./notes.sh [global-options] <command> -- [arguments...]
```

---

## Action Matrix

| Intent | Command | Target Arguments | Pre-conditions / Notes |
| :--- | :--- | :--- | :--- |
| **Search Notes** | `search-notes` | `<query>` | None |
| **List Folder Notes** | `list-notes` | `<folder>` | None |
| **List Folders** | `list-folders` | None | None |
| **Read note by ID** | `read-note-id` | `<note_id>` | Returns metadata + note body |
| **Read note by Title** | `read-note-title`| `<title> [folder]` | Fails (Code 4) if title is ambiguous |
| **Create Text Note** | `create-note-text`| `<title> <folder> <plain_text>` | Plain text is auto-escaped safely |
| **Create HTML Note** | `create-note-html`| `<title> <folder> <body_html>` | Accepts trusted HTML layout |
| **Create Folder** | `create-folder` | `<folder>` | Returns `already_exists: true/false` |
| **Append Text** | `append-note-text`| `<note_id> <plain_text>` | Supports optional `--if-modified-at` |
| **Append HTML** | `append-note-html`| `<note_id> <body_html>` | Supports optional `--if-modified-at` |
| **Move Note** | `move-note-id` | `<note_id> <dest_folder>` | Requires `--confirm` |
| **Delete Note** | `delete-note-id` | `<note_id>` | Requires `--confirm` |
| **Delete Folder** | `delete-folder` | `<folder>` | Requires `--confirm`. Fails (Code 4) if folder name is ambiguous |

*Add `--json` globally to receive clean, parseable JSON envelopes: `{"ok": true, "data": ...}`.*

---

## Exit Status Matrix

- **`0`**: Success
- **`2`**: Parameter/Syntax error (usage mismatch, invalid flag)
- **`3`**: Resource Not Found (folder or note ID not found)
- **`4`**: Ambiguity (multiple matches found for folder deletion, creation, or title lookups)
- **`5`**: Confirmation Required (refused destructive command because `--confirm` was missing)
- **`6`**: Native AppleScript/JXA execution failure
- **`7`**: Concurrency Conflict (note has been modified since your read request when `--if-modified-at` was set)

---

## Usage Examples

### 1. Retrieve a note's ID and Read its Content
```bash
./notes.sh --json search-notes "Daily Log"
# Returns standard JSON: {"ok": true, "data": [{"id": "x-coredata://...", "modified_at": "..."}]}
./notes.sh --json read-note-id "x-coredata://..."
```

### 2. Append content safely with Concurrency Lock
```bash
# Read note to get its last modified date: "2026-07-20T16:30:00.000Z"
./notes.sh --json read-note-id "x-coredata://..."
# Append using date guard to prevent overwriting parallel changes:
./notes.sh --json --if-modified-at "2026-07-20T16:30:00.000Z" append-note-text "x-coredata://..." -- "New line to append"
```

For complete CLI helper details, run `./notes.sh --help`.
