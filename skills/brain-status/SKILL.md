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

1. **Census first — this decides what appears.** Glob (or `ls`) `pages/Projects___*.md` and `pages/Tasks___*.md` — one free call. This file list, not the ripgrep in step 2, is authoritative for "what's in my brain": a page belongs on the dashboard because it exists, not because a later grep happened to match its content. Exclude session-archive pages (filename ending `___SessionArchive.md`). Also exclude `Projects___*.md` pages whose `type::` isn't `project` — e.g. `type:: task-index` (a project's task inventory, like `Projects___Unicorn-Globus___Tasks.md`) or `type:: project-note` (a standalone note, like `Projects___Unicorn-Globus___ClaudeCodeAutomation.md`). Both match the glob but are not projects; counting them would inflate both the dashboard and the "N projects have no digest" line in step 4 with pages that were never supposed to carry one (`skills/_shared/digest.md`'s scope rule).

2. **Collect every census page's state in one call.** Digest properties make the whole dashboard greppable:

   ```
   rg "^(type|status|last-updated|focus|next|open|digest-updated):: " pages/ \
      -g "Projects___*.md" -g "Tasks___*.md"
   ```

   One result set gives, per page with a readable property block: its type, status, freshness, current focus, next action, and any open blocker. Exclude session-archive pages from the results (filename ending `___SessionArchive.md`, or `type:: session-archive` in the result).

3. **Reconcile the census against the grep.** The grep is a content search, not the page list — a page whose property block is damaged or absent produces zero hits and would otherwise vanish from the dashboard entirely, which for a memory tool reads as "the project isn't there." Match every census file (step 1) against the hits (step 2); any census file with **zero** hits is listed explicitly — "ProjectName — no properties, run brain-doctor" — never silently dropped. The census, not the grep, decides what is listed.

4. **Fall back per project, not wholesale.** A project page that has some properties but no `focus::` / `next::` has not been backfilled with a digest yet (distinct from step 3's zero-hit pages, which have no readable properties at all). For **those pages only**, use the section-targeted reads in `skills/_shared/section-locator.md` — property block, first bullet of `## Current Plan`, last entry of `## Session Log` — exactly as before. A partially-backfilled graph therefore degrades one page at a time, never all at once. Mention the count once at the end: "<N> projects have no digest — run brain-doctor to backfill." Report the real count; never a placeholder digit.

5. **Apply staleness rules.** Use `skills/_shared/staleness.md` to flag stale or abandoned projects. Also flag **digest drift**: step 2's results already carry both `digest-updated::` and `last-updated::` for every page with a digest, so the comparison costs no extra reads. Where the gap exceeds 30 days, the digest may be describing older content (e.g. another device still on v0.9.x saved without refreshing it, or a Logseq hand-edit) — flag it the same way stale projects are flagged, and mention the count once: "<N> projects have a stale digest — see `skills/_shared/digest.md` to rebuild." Report the real count; never a placeholder digit.

6. **Read cross-project decisions.** Check `pages/Decisions.md` for entries from the last 30 days.

7. **Read Meta date.** Check `pages/Meta.md` `last-updated::` only — don't read the whole file.

8. **Task summary — no extra reads.** The single ripgrep in step 2 already covered `pages/Tasks___*.md`. Group from those results: **active** and **blocked** tasks listed by ID with their status; **done** tasks collapsed to one count line ("N done"); tasks with no `status::` listed as "legacy — run brain-doctor to backfill". Where a task has a `focus::`, show it; otherwise show the ID alone.

9. **Present the dashboard.** For each project: name, status, staleness annotation (if any), digest-drift annotation (if any), current focus, open questions/blockers. Then: task summary (from step 8), recent cross-project decisions, total counts.

10. **Write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `viewed dashboard`.

## Example Output

```
Here's your brain status:

**LogseqBrain** (active, last updated <yyyy-MM-dd>)
Currently: <first bullet of Current Plan>
No blockers.

**ChivalricQuest** (active, last updated <yyyy-MM-dd>)
Currently: No active plan yet.
No blockers.

Tasks: CRMGM-2002 (active), CRMGM-1994 (blocked) · 31 done

2 projects tracked (2 active). No recent cross-project decisions.
```

## Analytics (brain stats)

Read-only aggregate view. Writes nothing except the journey-log entry. Stay token-frugal — use `skills/_shared/section-locator.md` for targeted reads; never full-read project pages.

When counting, **exclude template placeholder stubs** — the italic markers a fresh `brain-init` page seeds, e.g. `_Project-specific decisions._` under `## Decisions`, `_Session entries are added by brain-save._` under `## Session Log`, and `_No active plan yet._` under `## Current Plan`. They denote an empty section, so a section that contains only its stub counts as **0**, not 1.

1. **Projects.** Glob `pages/Projects___*.md`. Count total. Apply `skills/_shared/staleness.md`, then collapse its four levels into two buckets for the count: **active** = `fresh` + `aging`, **stale** = `stale` + `abandoned`. Exclude session-archive pages from the project count, and exclude pages whose `type::` isn't `project` (`task-index`, `project-note`, etc. — same exclusion as Dashboard step 1) — they match the glob but aren't projects.
2. **Decisions.** Count two distinct figures, because cross-project decisions are intentionally duplicated in both places (so never sum them): (a) **cross-project** decisions in `pages/Decisions.md`, and (b) decisions recorded on project pages (in their `## Decisions` sections; this includes the project-page copy of any cross-project decision). Break each down by `status::` value (e.g. accepted, superseded).
3. **Sessions.** For each project page, count real entries under `## Session Log` (section-targeted read; skip the placeholder stub). Sum across projects.
4. **Activity (recent window).** Glob `journals/*.md`. For journals dated within the last 30 days (filename `yyyy_MM_dd.md`), count bullets under `## Activity`. Report the total as the recent activity signal.
5. **Present** a compact block. The Tasks line is computed as in Dashboard step 8 — grouped from the **same single ripgrep** as step 2, which already covers `pages/Tasks___*.md`; no per-task reads. **legacy** = task pages with no `status::`.

   ```
   Brain stats:

   Projects: <N> (<active> active, <stale> stale)
   Tasks: <N> (<a> active, <b> blocked, <d> done, <l> legacy)
   Decisions: <P> on project pages, <X> cross-project (by status: <accepted> accepted, <superseded> superseded)
   Sessions logged: <S>
   Activity (last 30 days): <A> entries
   ```

6. **Write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `viewed brain stats`.

## Important Notes

- Concise overview, not a deep load — bias toward fewer reads.
- If no projects yet: "Your brain is empty. Use 'init brain project [name]' to add your first project."
