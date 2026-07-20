# Apple Notes Skill

Native Apple Notes automation for AI agents on macOS.
Uses only built-in `osascript` JXA and Notes.app — no MCP server, database access, third-party CLI, or background service.

## What it does

- List folders and notes
- Search and read notes (by title or unique ID)
- Create and append notes (handling plain text or HTML bodies)
- Move notes between folders
- Delete notes or folders only after explicit confirmation
- Organize notes in cautious batches

## Requirements

- macOS with Notes.app
- `osascript` (built in)
- Automation permission for your terminal/agent host to control Notes

## Install

Copy `skills/apple-notes` into your agent's skills directory.

```bash
git clone https://github.com/lishix520/apple-notes-skill.git
mkdir -p ~/.claude/skills
cp -R apple-notes-skill/skills/apple-notes ~/.claude/skills/apple-notes
chmod +x ~/.claude/skills/apple-notes/notes.sh
```

See [compatibility.md](file:///Users/mac/apple-notes-skill/docs/compatibility.md) for Codex, OpenClaw, and Hermes paths.

## Use

Ask your agent:

- “Search my Apple Notes for Qwen quantization.”
- “Read the project note named X and continue from its next steps.”
- “Create a note in Research with this summary.”
- “Move the confirmed notes from Inbox to Archive.”

### Minimal Run Example (Manual Test)
Verify permission and functionality directly in your terminal:
```bash
./notes.sh list-folders
./notes.sh search-notes "test"
```

## Safety & Privacy Model

- **Safe ID matching**: If multiple notes share the same title, operations refuse to run blindly and return exit code 4, requiring ID selection.
- **Enforced confirmation**: Destructive actions (delete, move) refuse to execute unless `--confirm` is provided (returns exit code 5).
- **Privacy First**: The skill accesses Notes only through standard macOS Apple Events (JXA); it does not read the sqlite databases directly or send note contents to any third-party service.

## Scope & Non-Goals

This is an Apple Notes operator, not a RAG system, database adapter, or general-purpose desktop automation framework.

Attachments, scans, drawings, checklists, shared-note collaboration, and nested folders are outside the current compatibility guarantee.

For design philosophy and advanced workflows, see [advanced-workflows.md](file:///Users/mac/apple-notes-skill/docs/advanced-workflows.md).

## License

MIT
