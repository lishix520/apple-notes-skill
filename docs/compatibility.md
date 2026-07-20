# Agent Compatibility & Installation

This skill conforms to standard filesystem-based skill structures. Depending on the agent host, the installation directory varies.

---

## 1. Codex

Codex loads skills from a user-scoped directory.

**Install Path**:
`~/.codex/skills/apple-notes`

**Command**:
```bash
git clone https://github.com/lishix520/apple-notes-skill.git
cp -R apple-notes-skill/skills/apple-notes ~/.codex/skills/apple-notes
```

---

## 2. Claude Code

Claude Code supports project-local custom skills.

**Install Path**:
`./.claude/skills/apple-notes`

**Command**:
```bash
git clone https://github.com/lishix520/apple-notes-skill.git
mkdir -p .claude/skills
cp -R apple-notes-skill/skills/apple-notes .claude/skills/apple-notes
```

---

## 3. OpenClaw

OpenClaw supports AgentSkills-compatible directories. You can install it globally or workspace-scoped.

**Install Paths**:
- Global: `~/.openclaw/skills/apple-notes`
- Workspace: `<workspace>/skills/apple-notes` (takes precedence)

**Command**:
```bash
cp -R apple-notes-skill/skills/apple-notes ~/.openclaw/skills/apple-notes
```

---

## 4. Hermes

Hermes treats installed skills as slash commands and expects them in a dedicated folder.

**Install Path**:
`~/.hermes/skills/apple-notes`

**Command**:
```bash
cp -R apple-notes-skill/skills/apple-notes ~/.hermes/skills/apple-notes
```
