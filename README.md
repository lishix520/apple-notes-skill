# Apple Notes Skill

Native Apple Notes automation for AI agents on macOS.
Uses only built-in `osascript` and Notes.app — no MCP server, database access, third-party CLI, or background service.

## What it does

- **Create**: Create notes and folders cleanly.
- **Read**: Read note bodies safely.
- **Update**: Append structured HTML content to existing notes.
- **Delete / Move**: Move notes between folders, and delete notes with safety checks.
- **Query / Count**: Search notes globally, list folders/notes, get modification dates, and count notes.

## Requirements

- macOS with Notes.app
- `osascript` (built in)
- Automation permission for your terminal / agent host to control Notes

## Install

Copy `skills/apple-notes` into your agent's skills directory.

```bash
git clone https://github.com/lishix520/apple-notes-skill.git
cp -R apple-notes-skill/skills/apple-notes ~/.claude/skills/apple-notes
```

See [compatibility.md](file:///Users/mac/apple-notes-skill/docs/compatibility.md) for Codex, OpenClaw, and Hermes paths.

## Use

Ask your agent:

- “Create a note in folder 'Work' named 'Daily Update'.”
- “Read my Apple Notes project note named 'Launch Checklist'.”
- “Append this bullet point to the note 'Shopping List' in folder 'Personal'.”
- “Move the note 'Old Ideas' from folder 'Inbox' to 'Archive'.”
- “Search my Apple Notes globally for 'Qwen'.”

## Safety Model

- Search before creating to avoid duplicates.
- Append content instead of overwriting existing notes.
- Confirm explicitly before moving or deleting.
- Escape untrusted plain text before writing (note bodies are HTML).
- Let AppleScript errors bubble up naturally.

## Scope & Design Philosophy

This is an Apple Notes operator, not a RAG system, database adapter, or general-purpose desktop automation framework.

For design philosophy, flat folder taxonomy guidelines, and batch organization case studies, see [advanced-workflows.md](file:///Users/mac/apple-notes-skill/docs/advanced-workflows.md).

## License

MIT
