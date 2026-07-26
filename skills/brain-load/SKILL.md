---
name: brain-load
description: >
  Load project context from the Claude Brain Logseq graph into the current session.
  Triggers: "load brain", "load <project>", "resume <project>", "continue work on
  <project>", "what do we know about <topic>". Don't fire for write operations
  (use brain-save), generic questions about Logseq itself, or "open <file>" /
  "switch to <branch>" requests that mean opening files or switching git branches
  rather than loading project memory.
---

# Brain Load

Read project context from the Claude Brain Logseq graph and present it to Claude so work can continue seamlessly across sessions and devices.

## Prerequisites

Resolve the graph path per `skills/_shared/path-resolution.md`.

## Loading a Specific Project

When the user says "load <project>" or similar:

1. **Find the project page** using the algorithm in `references/matching.md`.

2. **Read the digest — one Read.** `Read(page, offset 0, limit 20)` captures the page-top property block and the whole `## Digest` (see `skills/_shared/digest.md`). It may overshoot a few lines into `## Overview`; that is acceptable and bounded. This is the entire brief-mode read.

   **Check before you use it: the read must contain a `Map:` bullet.** Task pages have no fixed template, so a property block can run long (extra task-specific properties push everything below it further down the file) — a `limit 20` read can land past the end of `## Digest` and return digest-shaped bullets with no Map. If `Map:` is not in what you read, the property block is longer than the bound, not that the page lacks a Map — re-read with a larger `limit` (e.g. 30), or `grep -nE '^(- )?## '` for the exact section span and read from there. **Never present a digest whose Map you did not see** — a digest without a Map is not a shorter digest, it is a page you cannot state coverage for.

   **If that still shows no Map, check the span, not another guess at `limit`.** Bound a read to the exact `## Digest` section — the heading line from the grep through the line before the next `## ` heading. If that span-bounded read of the *whole* section still has no `Map:` bullet, the page genuinely lacks one: the property block was never the problem. Say so, treat this load's coverage as unknown until a rebuild, and offer to build a digest per `skills/_shared/digest.md` — the same offer step 2's no-`## Digest` fallback below makes.

   **Check for drift too — it's free.** The same property block already carries both `last-updated::` and `digest-updated::`; compare them. If `digest-updated::` is more than 30 days behind `last-updated::`, the digest may describe older content than the page now holds — e.g. another device still on v0.9.x saved without refreshing the digest, or the user hand-edited the page directly in Logseq. Note this in the step 8 coverage statement and **suggest** the rebuild procedure in `skills/_shared/digest.md` — never rebuild unprompted.

   **If there is no `## Digest`:** fall back to the pre-digest brief mode — property block, first 5 Overview bullets, full Current Plan, and the Session Log **tail** (bounded to last 3 entries *or* ~4 KB, whichever is smaller — the byte-bounded tail recipe in `skills/_shared/section-locator.md`: take fewer than 3 entries when recent ones run large, never zero, and report how many of how many you read), section-targeted per `skills/_shared/section-locator.md` — and then offer to build one, quoting the fallback read you just measured rather than a remembered constant: *"This page has no digest yet — want me to build one? This fallback read was ~<X> KB; a digest brings future loads to ≤ ~2 KB of digest content (plus a small shrink-to-fit check of today's journal, targeting ~2 KB, when it mentions this project) regardless of page size."* `<X>` is the sum of the byte counts the section-targeted reads already produced (measure-before-read, `skills/_shared/section-locator.md`) — never restate a figure measured on a different page. Build only on confirmation, per the rebuild-from-source procedure in `skills/_shared/digest.md`. Every existing graph therefore keeps working exactly as it does today until it is backfilled.

3. **Stop reading — digest path only.** If the fallback in step 2 ran, it has already read what it needs; skip to step 4. On the digest path, do **not** pre-load Overview, Current Plan, Implementation, Decisions, Session Log, linked pages, or task pages. The Map bullet says what exists and how big it is; fetch from it on demand per `skills/_shared/escalation.md` (on the fallback path, escalation starts at level 2 — targeted grep — since levels 0–1 presuppose a digest and Map bullet) when the conversation actually needs it — announced, one level at a time.

4. **Read today's journal's mention(s) of this project, shrunk to fit** (`journals/yyyy_MM_dd.md`) if the file exists — not the whole journal, which aggregates every project worked on that day and can run past 10 KB (measured on the reference graph: 10,152 B).

   **Search the whole journal — never scope the grep to `## Sessions`.** 10 of 69 real journals carry no `## Sessions` heading at all: Logseq's empty-heading stripping (`skills/_shared/logseq-format.md`) can remove the heading text while leaving its session-bullet children in place, orphaned under a bare `-`. 8 of those 10 still carry real `[[Projects/<Name>]]:` session bullets this way — a `## Sessions`-scoped grep finds nothing on those journal-days and silently drops the very note this step exists to capture. Grep the **whole file** instead:
   ```bash
   grep -nE '^[[:space:]]*- \[\[Projects/<MatchedName>\]\]' "journals/<today>.md"
   ```
   This finds the project's top-level session bullet(s) wherever they actually live — under an intact `## Sessions` heading, under a heading Logseq stripped to empty, or bare at the top of the file.

   **Read every match — not "the bullet."** 10+ real journal-days carry 3–5 top-level bullets for one project in a single day (measured: `2026_04_25` alone has 4, all for the same project). For each match, read the bullet and its children — the deeper-indented lines immediately following it, stopping at the next line at the same or shallower indentation, the next `## ` heading, or EOF — same reasoning as before, just applied to every match found instead of assuming there is only one.

   **Shrink-to-fit against the ~2 KB target — this is not automatically true, it has to be enforced.** Measured live, the matching project's bullets-and-children exceed 2 KB on several real journal-days — **8,468 B on `2026_04_25`** (effectively the whole file that day: 4 bullets for one project, no `## Sessions` heading to compete with) and several more days in the 2–5 KB range. Apply the same shrink recipe `skills/_shared/section-locator.md`'s "Reading a section's tail" already uses for `## Session Log`, generalized from one named section to the whole file: take all matches; if the total is over ~2 KB, drop the **oldest** match and re-measure; repeat until under budget or exactly one match remains — never read zero when at least one match exists, even if that single match alone exceeds the cap. On `2026_04_25` this lands on the most recent 1 of 4 matches, **1,248 B** (down from 8,468 B for all 4) — under the target. State what was actually read: "N of M today's-session mentions read, X KB of Y KB."

   No match at all → nothing to read for this project today, move on. This captures session notes from earlier today without pulling in every other project's activity.

5. **Active tasks.** Name the task IDs the digest mentions and stop there. Do not read `pages/Tasks___<ID>.md` or any external `plan.md` in brief mode — escalate on demand per `skills/_shared/escalation.md`. In full mode, read a referenced task page's digest (one Read) rather than its body, and skip pages whose page-top `status::` is `done`. A task page with no digest of its own falls back to its page-top property block plus its first section — **measured first and capped at 8 KB** per `skills/_shared/section-locator.md`. Task pages have no fixed template, so a "first section" can be arbitrarily long; over the cap, grep inside it instead (`skills/_shared/escalation.md` level 2). Never read its whole body.

   **Fallback path:** with no digest, take task IDs from the `## Current Plan` section step 2 already read, and skip task pages whose page-top `status::` is `done` — the same rule the digest path inherits. Do not read task page bodies either way.

6. **Apply staleness rules.** Use `skills/_shared/staleness.md` against the project's `last-updated::` and `status::`.

7. **Surface session continuity hints — from the digest, not the Session Log.** `focus::` is what was being worked on, `next::` is the immediate next action, `open::` (when present) is the blocker. Frame as: "Picking up where you left off — focus: [focus]. Next: [next]. Open: [open]." No Session Log read is required to say this.

   **Fallback path:** with no digest there are no `focus::` / `next::` / `open::` properties. Build the same hint from the most recent Session Log entry step 2 already read — what was last worked on, plus any `open-questions::` on that entry. Frame it identically, so the two paths are indistinguishable to the user.

8. **Present a context summary, with an explicit coverage statement.** Give project name, status, staleness annotation, the digest bullets, and the continuity hint from step 7 — then say what was *not* read, from the Map bullet:

   > Loaded digest for Unicorn-Globus (active, updated 2026-07-24).
   > Focus: Hangfire unification — phase 2 of 4. Next: CRMGM-2016 rollout to STAGE.
   > **Not read:** Session Log 87 KB (47 entries), Active Tasks 10 KB, Current Plan 3 KB, Decisions 2 KB (2). Ask and I'll grep any of it.

   Quote whatever the Map actually lists — the field list is derived per page (`skills/_shared/digest.md`), not the fixed four shown here; a page whose Map surfaces `Active Tasks` or any other section says so, because that section is what the digest chose not to read on that particular page. The Map bullet itself separates each label from its figure with a reserved ` | ` token (e.g. `Session Log | 87 KB (47 entries)`) so a heading full of its own digits and punctuation parses unambiguously — paraphrase that into comma-separated prose here, as the example above does, rather than quoting the `|` verbatim.

   This is mandatory, not decorative — see "Truncation honesty" in `skills/_shared/section-locator.md`. Presenting a digest without saying what it omits is what lets the model reason from a fragment as though it held the whole history.

   **Digest drift.** If step 2 found `digest-updated::` more than 30 days behind `last-updated::`, add one line surfacing it and offering the rebuild — suggest only, never rebuild without confirmation:

   > Digest last refreshed 2026-05-01; page last updated 2026-07-24 — it may be describing older content. Want me to rebuild it (`skills/_shared/digest.md`)?

   **Fallback path:** there is no Map bullet to quote, so state coverage from what the fallback deliberately skipped — measure it rather than guessing (`skills/_shared/section-locator.md`, measure-before-read):

   > Loaded brief context for SELOS (active, updated 2026-07-21).
   > **Not read:** Implementation, Decisions, Session Log beyond the tail actually read (1 of 12 entries, 2.8 KB of 29.6 KB — capped below 3 because recent entries run large), linked pages, done task pages. Say "load full" for all of it, or ask and I'll grep.

   Quantify what you can — the sizes and counts come free from the measure-before-read step, and a number is harder to gloss over than a section name.

   The requirement is identical on both paths: never present partial content without saying what is missing.

9. **Write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `loaded [[Projects/<MatchedName>]] (digest)` when the digest path ran, `loaded [[Projects/<MatchedName>]] (brief)` when the fallback ran, `loaded [[Projects/<MatchedName>]] (full)` in full mode.

## Loading General Context

When the user says "load brain" without a project:

1. Read `pages/Index.md` for the list of all projects.
2. Read `pages/Meta.md` for user preferences and conventions.
3. Present a high-level overview: active projects, cross-project decisions, user preferences.
4. Write a journey-log entry: `loaded brain overview`.

## Searching Across the Brain

When the user asks "what do we know about X" or similar, follow the algorithm in `references/search.md`. After presenting findings, write a journey-log entry: `searched "X" · N hits`. Label hits from done-task pages and session-archive pages as such in the results, so cold context is recognizable.

## Load Modes: Digest, Brief (fallback), Full

**Digest mode** (default — "load <project>"):
1. One `Read(page, offset 0, limit 20)` — properties + `## Digest`.
2. **The read must contain a `Map:` bullet.** If it does not, the property block ran longer than the bound — re-read with a larger `limit`, or `grep -nE '^(- )?## '` for the exact span. Never present a digest whose Map you did not see.
3. Plus today's journal's mention(s) of this project, if any (step 4 above) — **shrunk to target ~2 KB, not bounded to it.** The grep is whole-file (never scoped to `## Sessions` — 10 of 69 real journals lack one) and every match is read, so the target is enforced by dropping the oldest matches first, same as the Session Log tail recipe, not by a hard read-size ceiling: a single oversized match is still read whole rather than dropped to zero. Measured worst case among real journals: `2026_04_25` shrinks from 8,468 B (all 4 matches) to 1,248 B (the most recent 1). Nothing else beyond the digest and that one shrunk journal check. **~4 KB total is a target** (~2 KB digest + ~2 KB journal), not a guarantee — a day with one large session mention can push the journal component over, in which case this step reports the actual bytes read rather than silently capping. Not the "≤ ~2 KB, nothing else" this step claimed before wave E3, which silently ignored the journal read every digest-mode load already performs.
4. Everything else arrives through `skills/_shared/escalation.md`, announced, when the conversation needs it.

**Brief mode** (automatic fallback — the page has no `## Digest`): the pre-digest behaviour, unchanged:
1. Properties (type, status, last-updated)
2. Overview (first 5 bullets only)
3. Current Plan (full)
4. Session Log tail — last 3 entries *or* ~4 KB, whichever is smaller (byte-bounded; see the tail recipe in `skills/_shared/section-locator.md`)
5. Skip Implementation, Decisions, linked context, `done` task pages, and session-archive pages (`type:: session-archive`)

Then state coverage as in step 8, mention that more is available — "Say 'load full' for decisions, implementation details, and full history" — and offer to build a digest.

**Full mode** ("load <project> full", "load everything about <project>"):
1. All properties and the digest
2. Full Overview, Current Plan, Implementation
3. All Decisions
4. Last 10 Session Log entries — **byte-bounded**: last 10 entries *or* ~8 KB (the per-section cap), whichever is smaller, using the shrink-until-under-cap recipe in `skills/_shared/section-locator.md`'s "Reading a section's tail" (never zero). "Last 10" alone is entry-denominated and, measured live, already exceeds the entire 24 KB ceiling by itself on real pages (25–37 KB for three different projects) — the same defect the fallback tail was byte-bounded for at 3-entry scale.
5. Related context pages (follow `[[links]]`), referenced task pages by digest
6. Today's journal entry

**State the cost before spending it, when it's big.** Before reading steps 1–6, size each targeted section (`wc -c`, already free per "measure before you read") and sum them — including the *bounded* Session Log tail from step 4, not the raw entry count. If the total would exceed the 24 KB soft ceiling, say so and ask before reading, mirroring the consent gate `skills/_shared/escalation.md` rule 3 already requires for a whole-page read: *"Full load of <Project> comes to ~31 KB (Overview 4 KB, Current Plan 8 KB, Implementation 8 KB, Decisions 6 KB, Session Log tail 6 KB, capped from 2 of 12 entries) — that's over the usual ceiling. Read it all, or would you rather I stuck to the digest and escalated on demand?"* Under the ceiling → just read, no ask needed. This is in addition to, not instead of, reporting any overflow that remains after the bound and the ask — full mode still **reports the overflow** rather than truncating silently when a page's other sections (Implementation, Decisions) themselves run long.

In digest mode, mention what more is available: "Loaded the digest. Ask about anything in the Map and I'll fetch it, or say 'load full' for everything."

## Important Notes

- Be selective about reads. Token budget matters — on the digest path step 2 is a single bounded Read; on the fallback path use the section-targeted-read pattern in `skills/_shared/section-locator.md`. Never read a whole page to answer a question.
- After loading, confirm what's available and suggest next actions.
- All graph content is Logseq outliner format. See `CLAUDE.md` for invariants.
