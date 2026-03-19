# Apple Notes Skill

A lightweight Apple Notes skill for AI agents on macOS.

This project is for people who want an agent to work with Apple Notes reliably without re-discovering the access method every time. It focuses on practical Apple Notes operations, not on general summarization, translation, or knowledge work.

## What It Solves

Apple Notes is useful as a long-term working memory, inbox, and writing space, but agent access is awkward in practice.

It also has a practical product advantage:

- built into macOS
- free
- syncs across Apple devices
- can replace part of what people use Obsidian or Notion for

This skill helps agents make better use of the system Notes app instead of forcing users into a separate tool stack.

Common problems:

- Agents waste time re-testing multiple access methods
- Notes get written as dense unreadable blocks
- Organizing large note sets is error-prone
- Folder naming and move rules are inconsistent
- Existing notes are easy to duplicate or overwrite by mistake

This skill fixes that by freezing a simple, validated operating method and a set of practical rules.

## Who It Is For

Use this if you:

- use Apple Notes on macOS
- want Codex, Claude Code, or another agent to read and write Notes
- prefer native tools over third-party stacks
- want a simple, auditable workflow

This is especially useful for:

- organizing uncategorized Apple Notes
- saving project progress into Notes
- saving processed content into Notes
- reusing Apple Notes as a continuity layer across sessions
- reading existing project notes as working context before continuing a task

## Scope

This skill covers Apple Notes operations:

- read notes
- search notes
- create notes
- append or update notes
- create folders
- move notes between folders
- delete notes with caution
- batch-organize messy note collections
- write content with cleaner structure

In practice, this also supports a continuity workflow:

- read the existing project note
- recover the current status, decisions, and next steps
- continue writing into the same note instead of starting from zero

This skill does not try to do everything.

Out of scope:

- summarization itself
- translation itself
- deep semantic classification systems
- RAG, MCP, vector search, or complex infra

Do the thinking work first. Use this skill to operate on Apple Notes.

## Validated Approach

The current implementation strategy is intentionally simple:

- use `osascript`
- use Apple Notes automation built into macOS
- avoid extra dependencies unless real usage proves they are needed

Why this approach:

- native to macOS
- no third-party installation required
- already validated in real note reads, writes, appends, moves, and folder cleanup

## Real Scenarios This Was Tested On

This draft was refined through actual use, not just theory.

Validated scenarios:

- reading and searching Apple Notes folders and notes
- creating and updating a skill draft note
- writing a structured article summary into Apple Notes
- reorganizing a large folder of 589 notes
- deleting confirmed-empty folders after reorganization

## Design Principles

- Prefer native over third-party
- Prefer simple over clever
- Search before create
- Append before overwrite
- Use flat folder names when practical
- Organize in multiple passes, not one giant leap
- Keep a catch-all folder for ambiguous leftovers
- Verify before destructive actions

## Folder Strategy

Apple Notes organization works better with practical flat folders than forced pseudo-hierarchies.

Examples of useful flat folders:

- `系统结构`
- `觉察与能量`
- `释放法与信念`
- `AI与记忆`
- `阅读与引用`
- `行动与方法`
- `金钱与生存`
- `主体与自我`
- `商业与产品`
- `对话摘录`
- `思辨片段`

## Known Limitations

- macOS only
- Apple Notes automation can be fragile
- note `body` often comes back as HTML-like content
- formatting must be handled explicitly on write
- large-scale classification by title is practical, but not perfect
- some note sets contain mixed forms: topic notes, dialogue snippets, abstract fragments

## Repository Structure

- `SKILL.md` contains the actual skill instructions
- `README.md` explains what the skill is for and how to think about it

The project is intentionally small. The goal is not more complexity; the goal is better real-world reliability.
