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

   **If there is no `## Digest`:** fall back to the pre-digest brief mode — property block, first 5 Overview bullets, full Current Plan, last 3 Session Log entries, section-targeted per `skills/_shared/section-locator.md` — and then offer to build one: *"This page has no digest yet — want me to build one? Future loads drop from ~4 KB to under 1 KB."* Build only on confirmation, per the rebuild-from-source procedure in `skills/_shared/digest.md`. Every existing graph therefore keeps working exactly as it does today until it is backfilled.

3. **Stop reading.** Do **not** pre-load Overview, Current Plan, Implementation, Decisions, Session Log, linked pages, or task pages. The Map bullet says what exists and how big it is; fetch from it on demand per `skills/_shared/escalation.md` when the conversation actually needs it — announced, one level at a time.

4. **Read today's journal** (`journals/yyyy_MM_dd.md`) if it exists — captures session notes from earlier today.

5. **Active tasks.** Name the task IDs the digest mentions and stop there. Do not read `pages/Tasks___<ID>.md` or any external `plan.md` in brief mode — escalate on demand per `skills/_shared/escalation.md`. In full mode, read a referenced task page's digest (one Read) rather than its body, and skip pages whose page-top `status::` is `done`.

6. **Apply staleness rules.** Use `skills/_shared/staleness.md` against the project's `last-updated::` and `status::`.

7. **Surface session continuity hints — from the digest, not the Session Log.** `focus::` is what was being worked on, `next::` is the immediate next action, `open::` (when present) is the blocker. Frame as: "Picking up where you left off — focus: [focus]. Next: [next]. Open: [open]." No Session Log read is required to say this.

8. **Present a context summary, with an explicit coverage statement.** Give project name, status, staleness annotation, the digest bullets, and the continuity hint from step 7 — then say what was *not* read, from the Map bullet:

   > Loaded digest for Unicorn-Globus (active, updated 2026-07-24).
   > Focus: Hangfire unification — phase 2 of 4. Next: CRMGM-2016 rollout to STAGE.
   > **Not read:** Session Log 89 KB (49 entries), Decisions 12, Implementation 4 KB. Ask and I'll grep any of it.

   This is mandatory, not decorative — see "Truncation honesty" in `skills/_shared/section-locator.md`. Presenting a digest without saying what it omits is what lets the model reason from a fragment as though it held the whole history.

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
2. Nothing else. ≤ ~2 KB regardless of page size.
3. Everything else arrives through `skills/_shared/escalation.md`, announced, when the conversation needs it.

**Brief mode** (automatic fallback — the page has no `## Digest`): the pre-digest behaviour, unchanged:
1. Properties (type, status, last-updated)
2. Overview (first 5 bullets only)
3. Current Plan (full)
4. Session Log (last 3 entries only)
5. Skip Implementation, Decisions, linked context, `done` task pages, and session-archive pages (`type:: session-archive`)

Then offer to build a digest.

**Full mode** ("load <project> full", "load everything about <project>"):
1. All properties and the digest
2. Full Overview, Current Plan, Implementation
3. All Decisions
4. Last 10 Session Log entries
5. Related context pages (follow `[[links]]`), referenced task pages by digest
6. Today's journal entry

Full mode keeps the ≤ 24 KB soft ceiling from `skills/_shared/section-locator.md` and **reports the overflow** when a page exceeds it rather than truncating silently.

In digest mode, mention what more is available: "Loaded the digest. Ask about anything in the Map and I'll fetch it, or say 'load full' for everything."

## Important Notes

- Be selective about reads. Token budget matters — use the section-targeted-read pattern in step 2 of "Loading a Specific Project" rather than reading whole pages.
- After loading, confirm what's available and suggest next actions.
- All graph content is Logseq outliner format. See `CLAUDE.md` for invariants.
