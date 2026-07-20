# Apple Notes Skill

Native Apple Notes automation for AI agents on macOS.
Uses only built-in `osascript` and Notes.app — no MCP server,
database access, third-party CLI, or background service.

## What it does

- List folders and notes
- Search and read notes
- Create and append notes with HTML bodies
- Move notes between folders
- Delete notes only after explicit confirmation
- Organize notes in cautious batches

## Requirements

- macOS with Notes.app
- `osascript` (built in)
- Automation permission for your terminal/agent host to control Notes

## Install

Copy `skills/apple-notes` into your agent's skills directory.

```bash
git clone https://github.com/lishix520/apple-notes-skill.git
cp -R apple-notes-skill/skills/apple-notes ~/.claude/skills/apple-notes
```

See `docs/compatibility.md` for Codex, OpenClaw, and Hermes paths.

## Use

Ask your agent:

- “Search my Apple Notes for Qwen quantization.”
- “Read the project note named X and continue from its next steps.”
- “Create a note in Research with this summary.”
- “Move the confirmed notes from Inbox to Archive.”

## Safety model

- Search before creating
- Use note IDs when an action changes existing data
- Append before overwriting
- Confirm before moving or deleting
- Never suppress AppleScript errors
- Notes bodies are HTML; escape untrusted plain text before writing

## Scope

This is an Apple Notes operator, not a RAG system, database adapter,
or general-purpose desktop automation framework.

## License

MIT
