---
name: brain-load
description: >
  Load project context from the Claude Brain Logseq graph into the current session.
  Use when the user says "load brain", "load Globus", "load project X",
  "what do we know about X", "get context for X", "brain context",
  "continue work on X", or wants to restore project knowledge from a previous session.
---

# Brain Load

Read project context from the Claude Brain Logseq graph and present it to Claude so work can continue seamlessly across sessions and devices.

## Prerequisites

The user's ClaudeBrain Logseq graph folder must be accessible.

**In Cowork:** If no folder is connected, use `request_cowork_directory` to ask the user to select their ClaudeBrain graph folder.

**In Claude Code / CLI:** The user should provide the graph path, or read it from the `LOGSEQ_BRAIN_PATH` environment variable, or from `.brain-config.json` in the plugin root (`{"graphPath": "..."}`). As a last resort, ask the user for the path.

## Loading a Specific Project

When the user says "load [project name]" or similar:

1. **Find the project page.** Glob for `pages/Projects___*.md` in the graph folder to get all project pages. Extract the project name from each filename by removing the `Projects___` prefix and `.md` suffix. Then match the user's input against these names using this strategy (stop at the first match):
   - **Exact match**: user input equals the project name exactly
   - **Case-insensitive**: lowercased user input equals lowercased project name
   - **Fuzzy**: strip all spaces, hyphens, and underscores from BOTH the user's input and each project name, then compare lowercased versions (e.g., "chivalric quest" → "chivalricquest" matches "ChivalricQuest" → "chivalricquest")
   - **Substring**: check if the lowercased, stripped user input is contained within the lowercased, stripped project name (e.g., "quest" matches "ChivalricQuest")
   - If still no match or multiple matches, list all available project pages and let the user pick
   - If no project pages exist at all, tell the user: "No projects in the brain yet. Use 'init brain project [name]' to create one."

2. **Read the project page.** Parse the full content including:
   - Properties (type, status, last-updated)
   - Overview section
   - Current Plan section
   - Implementation section
   - Decisions section (focus on recent/active decisions)
   - Session Log (read the last 5-10 entries for recent context)

3. **Read related context.** Check if the project page links to other pages via `[[Page Name]]` references. If critical context pages exist, read those too — but be selective to conserve tokens.

4. **Read today's journal entry** if it exists (`journals/yyyy_MM_dd.md` using today's date with underscores). This may have session notes from earlier today.

5. **Present a context summary** to confirm what was loaded. Format it conversationally:
   - Project name and status
   - What the current plan/task is
   - Key recent decisions
   - Where things left off (last session log entry)
   - Any blockers or open questions noted

## Loading General Context

When the user says "load brain" without specifying a project:

1. Read `pages/Index.md` to get the list of all projects.
2. Read `pages/Meta.md` for user preferences and conventions.
3. Present a high-level overview: active projects, any cross-project decisions, and user preferences.

## Searching Across the Brain

When the user asks "what do we know about X" or wants to find something:

1. Use Grep to search across all `.md` files in the graph folder for the search term.
2. Read the most relevant matches.
3. Present findings with links to the source pages.

## Important Notes

- Be selective about what to load. Don't read every page — only what's relevant to the user's request. Token budget matters.
- After loading, confirm what context is now available and suggest what the user can do next.
- All content in the graph uses Logseq outliner format (bullet points). Properties use `key:: value` format.
- Page links use `[[Page Name]]` or `[[Namespace/Page Name]]` syntax.
- File names use triple underscore `___` for namespace separators.
- If a project page is empty or has only placeholder text, let the user know and suggest using brain-save to populate it.