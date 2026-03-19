---
name: apple-notes
description: Use this skill when the task involves reading, searching, creating, editing, organizing, or moving Apple Notes on macOS. This includes finding notes, creating folders, moving notes into folders, appending structured content to an existing note, and writing well-formatted content into Apple Notes without re-testing multiple access methods.
---

# Apple Notes

Use this skill for Apple Notes tasks on macOS.

Typical triggers:

- Read an existing Apple Note
- Search notes by title or content
- Create a note
- Append or update a note
- Create a folder
- Move a note into a folder
- Organize uncategorized notes
- Save project progress into Apple Notes
- Save processed content into a specific note

Do not use this skill for summarizing or translating itself. Do that work first, then use this skill to operate on Apple Notes.

Classification is allowed when it directly supports organization. If the task is to sort uncategorized notes, the agent may infer a practical destination folder and then move the note there. Keep the classification simple and action-oriented. Do not turn this skill into a general taxonomy design exercise.

## Preferred Method

Use the already validated Apple Notes access method first. Do not waste time retrying multiple unrelated approaches.

Default rule:

- Prefer `osascript` with Apple Notes automation
- Reuse the known working command pattern for the current machine
- Only switch approach if the preferred method clearly fails

## Working Style

When operating on Apple Notes:

- Search before creating when there is any chance the note already exists
- Prefer append/update over replacing the whole note
- Keep formatting clean and readable
- Be conservative with move and delete
- If the target note is ambiguous, stop and clarify instead of guessing

## Practical Workflows

### Organize Uncategorized Notes

- Search or list candidate notes first
- Infer a reasonable folder based on title and content
- Create the folder if it does not exist
- Preview the source note and destination folder before moving in bulk
- If classification confidence is low, stop and ask instead of guessing

For large messy folders, do not try to solve everything in one pass.

Preferred sequence:

- First pass: move only high-confidence matches
- Second pass: create a few practical flat folders for recurring themes
- Final pass: move the leftovers into a deliberate catch-all folder instead of leaving them unorganized forever

For Apple Notes specifically, flat folder names are safer than fake hierarchical names.

Prefer:

- `系统结构`
- `觉察与能量`
- `行动与方法`
- `对话摘录`
- `思辨片段`

Avoid creating pseudo-nested names unless you know the current Notes setup supports them well.

### Update Project Progress

- Search for the existing project note first
- If found, append a dated update section
- If not found, create a project note in the best matching folder
- Preserve existing history; do not replace the whole note

### Save Processed Content Into Notes

- Finish the upstream work first, such as extraction, translation, or summary
- Search for the target note or decide whether a new one is needed
- Write the final content in a clean Apple Notes friendly structure

## Core Actions

### Read Notes

Use when the user wants existing content, project history, or note contents.

Default behavior:

- Find the note first by title or nearby keywords
- If multiple results match, narrow before reading
- Read the target note only after identifying it confidently

### Search Notes

Use search when:

- The exact note name is unknown
- The user refers to a topic, not a title
- You need to locate candidate notes before moving or updating

Return the best matching notes first, then act on the chosen note.

### Create Note

Create a new note only when:

- Search shows no existing target note
- The user explicitly wants a new note

Before creating:

- Choose the correct folder if known
- Use a clear title
- Write content in clean structure, not a text block dump

### Edit Or Append

Prefer append/update when a note already exists.

Default rule:

- Append new sections rather than rewriting old content
- Preserve existing structure unless the user asks for cleanup
- Avoid destroying manually written content

### Create Folder

Create folders when:

- The user is organizing notes
- A project needs a stable home
- A clear category does not already exist

Use simple, stable names. Do not create many near-duplicate folders.

### Move Note

Move a note only after confirming the destination is correct.

Default rule:

- Search and identify the note
- Confirm the destination folder is the intended one
- For bulk moves, preview the mapping before executing

### Delete Note

Delete is high risk.

Default rule:

- Do not delete unless the user clearly asks
- If the target is ambiguous, clarify first
- Prefer caution over speed

## Formatting Rules

Never write dense wall-of-text notes if the content is more than a few lines.

Use clean spacing:

- A clear title
- Short intro if needed
- Blank lines between paragraphs
- Bullets for lists
- Headings for sections

Recommended patterns:

### Project Update

Use:

```md
# Project Name

## Update - YYYY-MM-DD

### Status

Short status summary.

### Done

- Item

### In Progress

- Item

### Next

- Item

### Risks / Blockers

- Item
```

### Article Notes

Use:

```md
# Article Title

## Source

- Link:
- Date:

## Summary

Short summary.

## Key Points

- Point

## Notes

- Observation
```

### General Structured Note

Use:

```md
# Title

## Context

Short context.

## Details

- Item

## Next Steps

- Item
```

## Safety Rules

- Do not overwrite an entire note unless explicitly asked
- Do not move notes when the destination is uncertain
- Do not delete notes casually
- Do not create duplicate notes if search can resolve the target
- Do not dump raw text into a note without formatting
- Do not keep retrying random Apple Notes access methods

## Good Defaults

- Search first
- Append second
- Create only when necessary
- Format before writing
- Ask before destructive actions

## Verified `osascript` Patterns

These patterns were validated on this machine. Reuse them before inventing new Apple Notes access methods.

### Get First Folder Name

```sh
osascript -e 'tell application "Notes" to get name of first folder'
```

### List Note Names In First Folder

```sh
osascript -e 'tell application "Notes" to get name of every note of first folder'
```

### Search Note Names By Title Fragment

```sh
osascript -e 'tell application "Notes" to get name of every note of first folder whose name contains "Apple Notes"'
```

### Read A Note Body By Title

```sh
osascript -e 'tell application "Notes" to get body of note "Apple Notes Skill" of first folder'
```

### Create A New Note

```applescript
tell application "Notes"
	activate
	set targetFolder to first folder
	make new note at targetFolder with properties {name:"Apple Notes Skill", body:"<h1>Apple Notes Skill</h1><br><div>Content</div>"}
end tell
```

### Create A New Note From The Shell

```sh
osascript <<'EOF'
tell application "Notes"
	activate
	set targetFolder to first folder
	make new note at targetFolder with properties {name:"Apple Notes Skill", body:"<h1>Apple Notes Skill</h1><br><div>Content</div>"}
end tell
EOF
```

Only add more code examples after validating them against the current machine.

## HTML Read And Write Notes

Apple Notes bodies often come back as HTML-ish content such as `<div>`, `<br>`, `<span>`, and inline styles.

When reading:

- Expect HTML in `body`
- Extract the useful text instead of trusting the raw string as final output
- Preserve structure when the note clearly contains headings or lists

When writing:

- Use explicit line breaks
- Prefer simple HTML structures over fancy rich text
- Keep the layout readable after Apple Notes renders it
- Validate that the written result is not collapsed into one dense block

## Error Handling

- If the target folder does not exist, create it first, then continue
- If search returns multiple note candidates, narrow the target before editing or moving
- If a note already exists, prefer update or append over duplicate creation
- If a write command succeeds but formatting looks wrong, adjust the HTML structure instead of retrying random access methods
- If Apple Notes automation fails, report the exact failing command and stop instead of switching tools blindly

## Batch Organization Gotchas

These were learned from reorganizing a large real Apple Notes folder.

- Do not assume nested folder naming is worth it. Flat names worked better in practice.
- Do not force every note into a clean abstract taxonomy. Real note sets include themes, fragments, and dialogue snippets.
- Large folders should be organized in multiple passes, not one giant classification leap.
- Use title-based classification first when it is clearly good enough. This is fast and practical.
- Keep a catch-all destination such as `思辨片段` for leftovers that are still useful but too ambiguous.
- Keep a separate folder such as `对话摘录` for conversational notes that are structurally different from topic notes.
- Delete empty folders after verification, not before.
- For destructive cleanup, count notes before and after the move.

## Known Limitations

Apple Notes automation can be fragile. When using this skill:

- Expect occasional scripting or permission issues
- Verify the note or folder target before high-risk actions
- Treat formatting carefully because Apple Notes is less predictable than plain Markdown files
- Prefer simple, readable structures that survive copy/write operations cleanly
