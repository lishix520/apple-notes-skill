# Advanced Workflows & Design Philosophy

This document contains design notes, classification philosophies, and scaling observations compiled from real-world usage of the Apple Notes Skill (v0.2.0).

---

## The 589-Note Organization Experience

During the initial validation of this skill, we reorganized a legacy folder containing **589 uncategorized notes**. The following lessons were learned from that process:

1. **Avoid Multi-Pass Deep Classification**: Do not try to move every note to a highly specialized taxonomy on the first run. Large folders should be organized in passes.
   - **First Pass**: Match clear, unambiguous titles (e.g., notes containing "Recipe" or "Meeting") and move them immediately.
   - **Second Pass**: Create a few broad flat folders for recurring themes (e.g., `商业与产品`, `行动与方法`).
   - **Final Pass**: Gather the hard-to-categorize leftovers into a deliberate catch-all folder (e.g., `思辨片段`) rather than leaving them in root forever.
2. **Flat Folders Win Over Hierarchies**: Apple Notes does not natively support deep nested directory logic cleanly via scripting. Flat folders are simpler, less fragile, and easier to search.
3. **Log Counts Before and After**: When performing bulk movements, count the notes in the source and destination folders before and after to ensure no note was lost or duplicated.

---

## Recommended Flat Folder Taxonomy

We suggest using a flat structure based on functional zones rather than strict hierarchical trees. Here is a battle-tested English/Chinese taxonomy:

- `系统结构` (System Architecture / Reference)
- `行动与方法` (Actions & Methods)
- `商业与产品` (Business & Products)
- `对话摘录` (Dialogue Snippets / Transcripts)
- `思辨片段` (Thoughts / Drafts)
- `阅读与引用` (Reading & References)
- `AI与记忆` (AI & Memory)

---

## Why Avoid Heavy Stacks (MCP, Vectors, DBs)?

This project is opinionated in its focus on **macOS-native simplicity**.

- **No MCP Server**: MCP (Model Context Protocol) is valuable for complex tool chains but introduces setup friction, daemon management, and protocol translations.
- **No Vector Database**: Implementing a local vector DB for RAG (Retrieval-Augmented Generation) on Apple Notes requires constant indexing, runs background services, and increases memory usage. For notes, direct keyword/title search + folder indexing is extremely fast and natively supported by macOS search indices.
- **Privacy & Portability**: Using `osascript` directly leaves zero traces in third-party services and relies on Apple's built-in sandbox and device syncing.
