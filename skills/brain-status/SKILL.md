---
name: brain-status
description: >
  Show a dashboard of all projects in the Claude Brain graph. Triggers: "brain
  status", "show projects", "show brain", "what's in my brain", "project
  dashboard", "brain overview", "list projects", "summary". Don't fire for loads
  (use brain-load) or saves (use brain-save).
---

# Brain Status

Display a quick dashboard of all projects in the Claude Brain graph — status, last activity, current focus, blockers.

## Prerequisites

Resolve the graph path per `skills/_shared/path-resolution.md`.

## Dashboard Generation

1. **List all projects.** Glob for `pages/Projects___*.md` in the graph folder. Extract project names.

2. **Read each project page selectively.** Use the section-targeted-read pattern (see `skills/brain-load/SKILL.md`) to extract:
   - `status::` property (top of file)
   - `last-updated::` property (top of file)
   - First bullet of `## Current Plan` (current focus)
   - Last entry of `## Session Log` (when last touched, with any `open-questions::`)

3. **Apply staleness rules.** Use `skills/_shared/staleness.md` to flag stale or abandoned projects.

4. **Read cross-project decisions.** Check `pages/Decisions.md` for entries from the last 30 days.

5. **Read Meta date.** Check `pages/Meta.md` `last-updated::` only — don't read the whole file.

6. **Present the dashboard.** For each project: name, status, staleness annotation (if any), current focus, open questions/blockers. Then: recent cross-project decisions, total counts.

7. **Write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `viewed dashboard`.

## Example Output

```
Here's your brain status:

**LogseqBrain** (active, last updated 2026-04-12)
Currently: Phase 6 — token-frugality and journey log
No blockers.

**ChivalricQuest** (active, last updated 2026-04-12)
Currently: No active plan yet.
No blockers.

2 projects tracked (2 active). No recent cross-project decisions.
```

## Important Notes

- Concise overview, not a deep load — bias toward fewer reads.
- If no projects yet: "Your brain is empty. Use 'init brain project [name]' to add your first project."
