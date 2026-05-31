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

Display a quick dashboard of all projects in the Claude Brain graph — status, last activity, current focus, blockers.

## Modes

- **Dashboard** (default, "brain status" / "show projects" / …): the per-project overview in "Dashboard Generation" below.
- **Analytics** ("brain stats" / "graph analytics" / "graph activity over time"): the aggregate counts in "Analytics (brain stats)" below.

Both resolve the graph path first (Prerequisites). Pick the mode from the trigger phrase; if ambiguous, default to Dashboard.

## Prerequisites

Resolve the graph path per `skills/_shared/path-resolution.md`.

## Dashboard Generation

1. **List all projects.** Glob for `pages/Projects___*.md` in the graph folder. Extract project names.

2. **Read each project page selectively** using the section-targeted-read pattern in `skills/_shared/section-locator.md`. For the dashboard you only need:
   - `status::` and `last-updated::` properties (in the property block at offset 0, limit 10)
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

**LogseqBrain** (active, last updated <yyyy-MM-dd>)
Currently: <first bullet of Current Plan>
No blockers.

**ChivalricQuest** (active, last updated <yyyy-MM-dd>)
Currently: No active plan yet.
No blockers.

2 projects tracked (2 active). No recent cross-project decisions.
```

## Analytics (brain stats)

Read-only aggregate view. Writes nothing except the journey-log entry. Stay token-frugal — use `skills/_shared/section-locator.md` for targeted reads; never full-read project pages.

When counting, **exclude template placeholder stubs** — the italic markers a fresh `brain-init` page seeds, e.g. `_Project-specific decisions._` under `## Decisions`, `_Session entries are added by brain-save._` under `## Session Log`, and `_No active plan yet._` under `## Current Plan`. They denote an empty section, so a section that contains only its stub counts as **0**, not 1.

1. **Projects.** Glob `pages/Projects___*.md`. Count total. Apply `skills/_shared/staleness.md`, then collapse its four levels into two buckets for the count: **active** = `fresh` + `aging`, **stale** = `stale` + `abandoned`.
2. **Decisions.** Count two distinct figures, because cross-project decisions are intentionally duplicated in both places (so never sum them): (a) **cross-project** decisions in `pages/Decisions.md`, and (b) decisions recorded on project pages (in their `## Decisions` sections; this includes the project-page copy of any cross-project decision). Break each down by `status::` value (e.g. accepted, superseded).
3. **Sessions.** For each project page, count real entries under `## Session Log` (section-targeted read; skip the placeholder stub). Sum across projects.
4. **Activity (recent window).** Glob `journals/*.md`. For journals dated within the last 30 days (filename `yyyy_MM_dd.md`), count bullets under `## Activity`. Report the total as the recent activity signal.
5. **Present** a compact block:

   ```
   Brain stats:

   Projects: <N> (<active> active, <stale> stale)
   Decisions: <P> on project pages, <X> cross-project (by status: <accepted> accepted, <superseded> superseded)
   Sessions logged: <S>
   Activity (last 30 days): <A> entries
   ```

6. **Write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `viewed brain stats`.

## Important Notes

- Concise overview, not a deep load — bias toward fewer reads.
- If no projects yet: "Your brain is empty. Use 'init brain project [name]' to add your first project."
