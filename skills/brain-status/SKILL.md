---
name: brain-status
description: >
  Show a dashboard of all projects in the Claude Brain graph.
  Use when the user says "brain status", "show projects", "what's in my brain",
  "project dashboard", "brain overview", "list projects", or wants a quick
  summary of all tracked projects and their current state.
---

# Brain Status

Display a quick dashboard of all projects in the Claude Brain graph — status, last activity, active tasks, and blockers.

## Prerequisites

The user's ClaudeBrain Logseq graph folder must be accessible.

**In Cowork:** If no folder is connected, use `request_cowork_directory` to ask the user to select their ClaudeBrain graph folder.

**In Claude Code / CLI:** The user should provide the graph path, or read it from the `LOGSEQ_BRAIN_PATH` environment variable, or from `.brain-config.json` in the plugin root (`{"graphPath": "..."}`). As a last resort, ask the user for the path.

## Dashboard Generation

1. **List all projects.** Glob for `pages/Projects___*.md` in the graph folder. Extract project names.

2. **Read each project page.** For each project, extract:
   - `status::` property (active, paused, completed, archived)
   - `last-updated::` property
   - The first bullet of the **Current Plan** section (what's being worked on)
   - The last entry of the **Session Log** section (when was the last session)
   - Any `open-questions::` from the most recent session log entry

3. **Read cross-project decisions.** Check `pages/Decisions.md` for any recent entries (last 30 days).

4. **Read Meta.** Check `pages/Meta.md` for last-updated date.

5. **Present the dashboard.** Format conversationally, like a standup summary:

   For each project:
   - Project name and status
   - Last activity date
   - Current focus (from plan)
   - Open questions or blockers (if any)

   Then:
   - Recent cross-project decisions (if any)
   - Total project count and how many are active

## Example Output

"Here's your brain status:

**LogseqBrain** (active, last updated 2026-04-12)
Currently: Phase 2 — richer context and search features
No blockers.

**ChivalricQuest** (active, last updated 2026-04-12)
Currently: No active plan yet.
No blockers.

2 projects tracked (2 active). No recent cross-project decisions."

## Important Notes

- Keep the dashboard concise — this is a quick overview, not a deep load.
- If a project hasn't been updated in over 14 days, flag it: "⚠ Last updated [N] days ago — may be stale."
- If there are no projects yet, tell the user: "Your brain is empty. Use 'init brain project [name]' to add your first project."
