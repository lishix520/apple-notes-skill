# Apple Notes Skill

A lightweight Apple Notes skill for AI agents on macOS.

This project is for people who want an agent to work with Apple Notes reliably without re-discovering the access method every time.

Most Apple Notes integrations are either missing, too heavy, or require extra installation. Even when an agent has already used a working Apple Notes path once, it often forgets and starts testing from zero again.

This skill fixes that by freezing a simple native workflow that has already been validated in real use.

## Why This Exists

This project is opinionated in a very specific way:

- native first
- simple first
- no third-party dependency unless real usage proves it is needed

That means:

- use the Apple Notes app you already have
- use macOS automation that already exists
- avoid extra databases, MCP servers, vector layers, or third-party CLIs unless they are truly necessary

For many users, this matters.

The practical value is:

- save money
- reduce tool sprawl
- reuse the Notes app that already syncs across Apple devices
- replace part of what would otherwise go into Obsidian or Notion

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

## Core Advantages

- pure macOS-native approach
- no required third-party install
- no extra index, database, or server
- real Apple Notes read / write / move workflows already tested
- practical batch organization rules
- designed for agents, not just for humans reading docs

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
- lower setup friction than more complex Apple Notes integrations

## Installation

This repo is just a skill folder. Installation is usually: place the folder where your agent loads custom skills from.

### Codex

Copy this repo into your Codex skills directory, for example:

```sh
cp -R apple-notes-skill ~/.codex/skills/apple-notes
```

### Claude Code

For repo-local usage, place it under:

```text
./.claude/skills/apple-notes
```

or in whatever shared Claude skills location your setup uses.

### Other agents

If your agent supports filesystem-based skills, copy this folder into that agent's skill directory and make sure it can read `SKILL.md`.

The minimum requirement is simple:

- the agent can load a skill from disk
- the agent can run `osascript`
- the agent has permission to automate Apple Notes

## Installing Through An Agent

If an agent can read this repository and has filesystem access, it can usually install the skill for you.

In practice, giving the agent the repository URL is not the same as installing the skill. The agent still needs to:

1. clone or download the repo
2. copy the folder into the correct local skills directory
3. make sure the agent can discover `SKILL.md`

Example prompts:

- `Install this Apple Notes skill from https://github.com/lishix520/apple-notes-skill into my Codex skills directory`
- `Clone this repo and place it under .claude/skills/apple-notes`
- `Set this up as a local skill and verify the agent can see SKILL.md`

Example install command for Codex:

```sh
cp -R apple-notes-skill ~/.codex/skills/apple-notes
```

So the short version is:

- repository URL lets the agent fetch the skill
- installation still requires placing it in the right local folder

## macOS Permission Setup

The first time an agent tries to control Apple Notes, macOS may ask for Automation permission.

If access fails, check:

- `System Settings > Privacy & Security > Automation`
- allow the terminal or agent app to control `Notes`

Without this permission, the skill will not work reliably.

## How To Use

After installation, invoke the skill by asking the agent to do Apple Notes work directly.

Examples:

- `Read my Apple Notes project note for X and continue from there`
- `Search Apple Notes for notes about Y`
- `Create an Apple Note for this summary`
- `Move these notes into better folders`
- `Organize my uncategorized Apple Notes`

The intended flow is:

1. the agent recognizes this is an Apple Notes task
2. it loads `SKILL.md`
3. it uses the validated `osascript` path
4. it follows the safety and formatting rules in the skill

## Cross-Agent Compatibility

This skill is designed to be portable at the content level.

What is portable:

- the instructions in `SKILL.md`
- the folder strategy
- the workflow rules
- the formatting rules
- the gotchas

What may vary by agent:

- where the skill folder is installed
- how the agent discovers skills
- how much shell / AppleScript access the agent has

So the main adaptation point is installation, not the core skill logic.

## Real Scenarios This Was Tested On

This skill was refined through actual use, not just theory.

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
- `CONTRIBUTING.md` explains how outside contributors can help
- `LICENSE` is MIT

The project is intentionally small. The goal is not more complexity; the goal is better real-world reliability.

## Author

- GitHub: [@lishix520](https://github.com/lishix520)

## License

MIT. See [LICENSE](./LICENSE).
