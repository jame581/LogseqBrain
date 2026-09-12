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

A dashboard of every project in the Claude Brain graph (status, last activity, focus, blockers), or aggregate analytics. Mechanical steps run through the helper (`skills/_shared/run-brain.md`).

## Prerequisites

Run `brain info` once, and use its `graph:` path for any Read this skill makes itself. If it exits 2, follow `skills/_shared/path-resolution.md`, then pass `--graph` to every call.

## Modes

- **Dashboard** (default).
- **Analytics** ("brain stats" / "graph analytics" / "graph activity over time").

## Dashboard

1. **One call: `brain status`.** It prints a TSV row per project and task page (`page type status last-updated digest-updated drift staleness focus next open`), then a counts line. Every page appears. A page whose property block is missing is listed as `no properties — run brain-doctor`, never dropped. Session archives are already excluded.
2. **Projects** are rows under `Projects/` whose `type` is `project`. Other types (`task-index`, `project-note`) match the file glob but are not projects, so leave them out of the list and the counts.
3. **Staleness and drift:** phrase each row's `staleness` per `skills/_shared/staleness.md`. When `drift` exceeds 30, the digest may describe older content; flag it, and give the count once.
4. **Pages without a digest** (`digest-updated` is `-`): show what the row has, one page at a time. For "Currently:", use the first bullet of `brain read <page> "Current Plan" --max 8192`; over the cap, say "Current Plan is N KB — not read". For the latest activity, use `brain tail <page> "Session Log" --entries 1 --max 2048`. End with "<N> projects have no digest — run brain-doctor to backfill" (the counts line gives N).
5. **Recent cross-project decisions:** `brain tail Decisions "Decision Log" --entries 10 --max 4096`; keep those from the last 30 days.
6. **Meta date:** `Read pages/Meta.md` with `limit 5` for `last-updated::` only.
7. **Tasks, from the same rows:** list active and blocked tasks by ID (with `focus` when present), collapse done tasks into "N done", and list tasks with no `status` as "legacy — run brain-doctor to backfill".
8. **Present** per project: name, status, staleness, drift note, focus, open. Then tasks, recent cross-project decisions and totals.
9. **`brain activity "viewed dashboard"`**.

## Analytics (brain stats)

Read-only. Exclude template stubs (`_…_` placeholder bullets) from every count.

1. **Projects and tasks:** from `brain status`. Active = `fresh` + `aging`; stale = `stale` + `abandoned` — derive both from each row's `staleness` column, never from the counts line's `(N active)` figure, which counts `status:: active` and means something else entirely.
2. **Decisions:** (a) cross-project, the entries in `pages/Decisions.md` (`brain sections Decisions`); (b) on project pages, each project's `Decisions` entry count from `brain sections <page>`. Never sum (a) and (b): cross-project decisions are deliberately duplicated. Break both down by `status::` (use `brain search "status:: superseded"` to count superseded ones).
3. **Sessions:** the sum of each project's `Session Log` entry count from `brain sections`.
4. **Activity:** bullets under `## Activity` in journals dated within the last 30 days. No helper command counts this; use a read-only shell pass over `journals/` (journal filenames sort as `yyyy_MM_dd`, so a string compare against the cutoff selects the files). `date -d` is GNU-only and `date -v` is BSD-only, so try both and fail closed — an empty cutoff would pass every journal and print an **all-time** count under a "last 30 days" label. If it prints `cutoff-unavailable`, report the activity figure as unavailable instead of the number. Match both `- ## Activity` and `## Activity`: Logseq may normalize a heading bullet to a bare heading, and a pattern matching only one form both misses its own bullets and fails to *close* the section, so other sections' bullets leak into the count. The helper's own `heading_text()` accepts both forms:
   ```
   CUTOFF=$(date -d '-30 days' +%Y_%m_%d 2>/dev/null || date -v-30d +%Y_%m_%d 2>/dev/null)
   [ -n "$CUTOFF" ] || echo cutoff-unavailable
   for f in journals/*.md; do [ "$(basename "$f" .md)" '>' "${CUTOFF:-9999_99_99}" ] && cat "$f"; done \
     | awk '/^[ \t]*(- )?## Activity/{f=1; next} /^[ \t]*(- )?## /{f=0} f && /^[ \t]*- /{n++} END{print n+0}'
   ```
5. **Present:**
   ```
   Brain stats:

   Projects: <N> (<active> active, <stale> stale)
   Tasks: <N> (<a> active, <b> blocked, <d> done, <l> legacy)
   Decisions: <P> on project pages, <X> cross-project (by status: <accepted> accepted, <superseded> superseded)
   Sessions logged: <S>
   Activity (last 30 days): <A> entries
   ```
6. **`brain activity "viewed brain stats"`**.

If there are no projects yet: "Your brain is empty. Use 'init brain project [name]' to add your first project."
