---
name: brain-load
description: >
  Load project context from the Claude Brain Logseq graph into the current session.
  Use when the user says "load brain", "load [project name]", "load project X",
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

5. **Check for active Jira tasks.** If the project's Current Plan section references Jira task IDs (e.g., PROJ-1234), and the task folder is accessible, optionally read the task's `plan.md` to provide richer context. Only do this in full mode or if the user specifically asks about a task. In brief mode, just mention the task IDs and their status.

6. **Check for stale context.** Compare the `last-updated::` property to today's date.
   - If last updated **more than 14 days ago**: flag prominently — "⚠ This project hasn't been updated in [N] days. Context may be outdated — verify before acting on it."
   - If last updated **7–14 days ago**: note gently — "Note: last updated [N] days ago."
   - If the project `status::` is `active` but it's been stale for 30+ days, suggest: "This project is marked active but hasn't been touched in a month. Want to update it or mark it paused?"

7. **Surface session continuity hints.** Look at the most recent Session Log entry and extract:
   - **What was last worked on**: the summary line of the last session
   - **Open questions**: if the last entry has an `open-questions::` property, surface those prominently — "Last time, you left these open: [questions]"
   - **Blockers**: if the last entry mentions blockers, surface them
   - Frame it as: "Picking up where you left off — last session ([date]): [summary]. Open questions: [list]"
   - If there are no open questions or blockers, just state where things left off

8. **Present a context summary** to confirm what was loaded. Format it conversationally:
   - Project name, status, and staleness warning (if any)
   - What the current plan/task is
   - Continuity hint: where things left off and open questions
   - Key recent decisions (full mode only, or if few)
   - Suggested next actions based on the plan and open questions

## Loading General Context

When the user says "load brain" without specifying a project:

1. Read `pages/Index.md` to get the list of all projects.
2. Read `pages/Meta.md` for user preferences and conventions.
3. Present a high-level overview: active projects, any cross-project decisions, and user preferences.

## Load Modes: Brief vs Full

By default, load in **brief** mode — prioritize the most useful sections to keep token usage low.

**Brief mode** (default — "load [project]"):
1. Properties (type, status, last-updated)
2. Overview (first 5 bullets only)
3. Current Plan (full)
4. Session Log (last 3 entries only)
5. Skip Implementation and Decisions unless the user asks

**Full mode** ("load [project] full", "load everything about [project]"):
1. All properties
2. Full Overview
3. Full Current Plan
4. Full Implementation
5. All Decisions
6. Last 10 Session Log entries
7. Related context pages (follow `[[links]]`)
8. Today's journal entry

When presenting the summary in brief mode, mention that more detail is available: "Loaded brief context. Say 'load full' for decisions, implementation details, and full history."

## Searching Across the Brain

When the user asks "what do we know about X", "search brain for X", "find X in brain", or wants to find something across projects:

1. **Search broadly.** Use Grep to search across all `.md` files in the `pages/` and `journals/` directories of the graph folder. Search for the term case-insensitively.

2. **Filter results.** Exclude matches from `logseq/bak/` (backup files) and `logseq/` config files. Focus on `pages/` and `journals/` matches.

3. **Group by source.** Organize results by which page they came from:
   - Project pages: show the project name and the matching section
   - Journal entries: show the date and the matching context
   - Meta/Decisions pages: show the matching entry

4. **Read relevant context.** For the top 3-5 most relevant matches, read a few lines of surrounding context to give a meaningful answer — don't just show the matching line.

5. **Present findings.** Format as:
   - "Found [term] in [N] places:"
   - For each match: the source page (as a `[[link]]`), the section, and the relevant context
   - If no matches found: "Nothing in the brain about [term]. This might be new territory."

## Important Notes

- Be selective about what to load. Don't read every page — only what's relevant to the user's request. Token budget matters.
- After loading, confirm what context is now available and suggest what the user can do next.
- All content in the graph uses Logseq outliner format (bullet points). Properties use `key:: value` format.
- Page links use `[[Page Name]]` or `[[Namespace/Page Name]]` syntax.
- File names use triple underscore `___` for namespace separators.
- If a project page is empty or has only placeholder text, let the user know and suggest using brain-save to populate it.