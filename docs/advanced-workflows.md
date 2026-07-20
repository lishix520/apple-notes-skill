# Advanced Workflows & Design Philosophy

This document contains design notes, classification philosophies, and scaling observations compiled from real-world usage of the Apple Notes Skill (v0.3.0).

---

## 1. The JXA (JavaScript for Automation) Architecture

In version v0.3.0, the core execution engine of the wrapper script `notes.sh` was upgraded from pure AppleScript to JXA (`osascript -l JavaScript`).

### Why JXA?
- **Native JSON Support**: JXA has the built-in `JSON` object. This makes returning structured metadata (like lists of notes or folder names) as JSON strings trivial, requiring no external CLI dependencies (like `jq` or `python`).
- **ISO-8601 UTC Dates**: Standard JavaScript `Date.prototype.toISOString()` returns consistent UTC timestamps. AppleScript's dates are locale-dependent strings (e.g. `Monday, July 20, 2026 at 4:46:51 PM`), which are highly unstable for parsing in different machine environments.
- **Modern JavaScript constructs**: Standard loops, arrays, string slicing, and case-insensitive `.includes()` matching significantly reduce the script's fragility.

---

## 2. Safe ID-Based Operations

Relying on note titles for mutations is unsafe because Apple Notes allows multiple notes to have the exact same title.
- To prevent accidental overwrite or deletion, v0.3.0 extracts unique `x-coredata://` IDs during search and list queries.
- When an agent wants to read, append, move, or delete, it must use the ID-based commands (e.g. `read-note-id`).
- Title-based mutations behave strictly: if multiple matching notes are found, they print the candidates to stderr and abort with exit code `4` (Ambiguity), forcing the client to specify a unique ID target.

---

## 3. The 589-Note Organization Experience

During the initial validation of this skill, we reorganized a legacy folder containing **589 uncategorized notes**. The following lessons were learned:

1. **Avoid Multi-Pass Deep Classification**: Do not try to move every note to a highly specialized taxonomy on the first run. Large folders should be organized in passes.
   - **First Pass**: Match clear, unambiguous titles (e.g., notes containing "Recipe" or "Meeting") and move them immediately.
   - **Second Pass**: Create a few broad flat folders for recurring themes (e.g., `商业与产品`, `行动与方法`).
   - **Final Pass**: Gather the hard-to-categorize leftovers into a deliberate catch-all folder (e.g., `思辨片段`) rather than leaving them in root forever.
2. **Flat Folders Win Over Hierarchies**: Apple Notes does not natively support deep nested directory logic cleanly via scripting. Flat folders are simpler, less fragile, and easier to search.
3. **Log Counts Before and After**: When performing bulk movements, count the notes in the source and destination folders before and after to ensure no note was lost or duplicated.
