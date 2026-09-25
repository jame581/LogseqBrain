---
name: brain-status
description: >
  Show a dashboard of all projects in the Claude Brain graph, or graph
  analytics. Dashboard triggers: "brain status", "show projects", "show brain",
  "what's in my brain", "project dashboard", "brain overview", "list projects",
  "summary". Analytics triggers: "brain stats", "graph analytics", "graph activity
  over time". Don't fire for loads (use brain-load) or saves (use brain-save).
---

# Brain Status

## Running the helper

- Bash: `sh "<this skill's base directory>/../_shared/bin/brain" <command> …`
- PowerShell-only Windows: `& "$(Split-Path (Split-Path (Get-Command git).Source))\bin\bash.exe" "<base>/../_shared/bin/brain" <command> …`
- Neither works: stop and say *"logseq-brain needs Git for Windows (Git Bash) — https://git-scm.com/download/win"*.
- In Cowork, always pass `--graph <connected folder>`. Elsewhere pass `--graph` only when the graph is not configured. It may go anywhere on the line. On exit 2 with `graph not resolved`, follow `skills/_shared/path-resolution.md`, then pass `--graph`.
- Put text arguments in single quotes; a `'` inside becomes `'\''`. In double quotes the shell runs backticks and expands `$`.
- Exit 0 clean, 1 findings (act on them), 2 error (act on its reason; don't retry blindly). Quote every `coverage:` line. Never recompute a figure it printed. Its `graph:` line is the folder for your own Read, Edit and Write calls.

Run `brain info` once first. For "brain stats", follow `references/analytics.md` instead of the dashboard.

## Dashboard

1. **`brain status`:** a TSV row per project and task page, then a counts line. The columns are `page type status last-updated digest-updated drift staleness focus next open`. A page with no property block is listed as `no properties — run brain-doctor`.
2. **Projects** are the `Projects/` rows whose `type` is `project`. Leave other types out of the list and the counts.
3. Phrase `staleness` per `skills/_shared/staleness.md`. When `drift` is over 30, flag the row, and give the count once.
4. **No digest** (`digest-updated` is `-`), one page at a time:
   - "Currently:": the first bullet of `brain read <page> 'Current Plan' --max 8192`. Over the cap, say "Current Plan is N KB — not read".
   - Latest activity: `brain tail <page> 'Session Log' --entries 1 --max 2048`.
   - End with "<N> projects have no digest — run brain-doctor to backfill".
5. **Cross-project decisions:** `brain tail Decisions 'Decision Log' --entries 10 --max 4096`. Keep those from the last 30 days.
6. **Meta date:** `Read pages/Meta.md` with `limit 5`, for `last-updated::`.
7. **Tasks:** list active and blocked tasks by ID (with `focus`). Collapse done tasks into "N done". List tasks with no `status` as "legacy — run brain-doctor to backfill".
8. **Present**, per project: name, status, staleness, drift, focus, open. Then tasks, decisions and totals. With no projects: "Your brain is empty. Use 'init brain project [name]' to add your first project."
9. `brain activity 'viewed dashboard'`.
