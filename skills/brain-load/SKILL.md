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

Read project context from the Claude Brain Logseq graph so work continues across sessions and devices. Mechanical steps run through the helper — see `skills/_shared/run-brain.md`.

## Prerequisites

Run `brain info` once, and use its `graph:` path for any Read this skill makes itself. If it exits 2, follow `skills/_shared/path-resolution.md`, then pass `--graph` to every call.

## Loading a Specific Project

1. **Find the page** per `references/matching.md`. If a helper call exits 2 with `page not found`, it may list near matches (it greps the typed key as a substring, so a typo that adds a character finds none); offer them when it does.

2. **One call: `brain digest <page>`.** It prints the page-top properties, the whole `## Digest` (however long the property block is), then:
   - `map: ok`: the Map is exact.
   - `map: stale` or `map: missing`: say so in step 7, and state coverage from the `computed:` line, not the stale Map. Loading is read-only: suggest a save, never write.
   - `digest: missing`: take the **fallback** below.
   - `drift: N days — over 30: suggest a rebuild`: mention it, and suggest the rebuild in `skills/_shared/digest.md`. Never rebuild unprompted.
   - `staleness:`: phrase it per `skills/_shared/staleness.md`.

3. **One call: `brain journal <page>`** for today's session notes on this page, already shrunk to ~2 KB. Quote its coverage line.

4. **Stop reading.** Do not pre-load Overview, Current Plan, Decisions, Session Log, linked pages, or task pages. The Map says what exists and how big it is. Fetch on demand per `skills/_shared/escalation.md`, announced, one level at a time.

5. **Active tasks.** Name the task IDs the digest mentions and stop there. In full mode, run `brain digest Tasks/<ID>` for each referenced task, skipping pages whose `status::` is `done`. Never read a task page's body.

6. **Continuity hint from the properties:** *"Picking up where you left off — focus: [focus]. Next: [next]. Open: [open]."*

7. **Present the summary with an explicit coverage statement.** Give the name, status, staleness, the digest bullets and the hint. Then say what was **not** read, from the Map. Each Map clause is `label | figure`; paraphrase the clauses into prose:

   > Loaded digest for Unicorn-Globus (active, updated 2026-09-07).
   > Focus: … Next: …
   > **Not read:** Session Log 151 KB (62 entries), Active Tasks 21 KB, Decisions 3 KB (3), Current Plan 3 KB, 7 smaller sections. Ask and I'll search any of it.

   This is mandatory. A digest presented without what it omits lets you reason from a fragment as if it were the whole history.

8. **`brain activity "loaded [[Projects/<Name>]] (digest)"`**, or `(brief)` for the fallback and `(full)` for full mode. Use `[[Tasks/<ID>]]` for a task page.

### Fallback: the page has no digest

`brain digest` already printed the properties and the section table. Read, each call bounded and each with a coverage line:
- **Overview, first 5 bullets:** `Read` with `offset` = the Overview heading line from the table and `limit 6`. State it as "first 5 bullets of ## Overview".
- **Current Plan:** `brain read <page> "Current Plan"` (8 KB cap; over it, `brain tail <page> "Current Plan" --max 8192`). Take the active task IDs from it, skipping task pages whose `status::` is `done`, as step 5 does.
- **Session Log tail:** `brain tail <page> "Session Log" --entries 3 --max 4096`.

Build the continuity hint from the newest Session Log entry and its `open-questions::`, and state coverage from the coverage lines. Then say what was **not** read: `brain digest` on a digest-less page already printed the whole section table (every section with its bytes) — list every section this fallback didn't fetch, with its bytes, straight from that table. Step 7's statement ("This is mandatory…") is mandatory on this path too; it is just sourced from the section table instead of the Map. (Escalation beyond this fallback starts at level 2 in `skills/_shared/escalation.md` — levels 0–1 presuppose a Map, which a digest-less page doesn't have.) Then offer a digest, quoting the bytes this fallback actually read (the sum of its coverage lines): *"This page has no digest yet — this load read ~X KB; a digest brings loads to about 2 KB. Build one?"* Build only on confirmation, via the Rebuild path in `skills/_shared/digest.md`.

## Full mode ("load <project> full")

Run `brain sections <page>` first and add up what you are about to read. That is Overview, Current Plan, Implementation and Decisions (each via `brain read`, 8 KB cap), plus `brain tail <page> "Session Log" --entries 10 --max 8192`. **If the total would exceed 24 KB, state it and ask before reading.** Report any section refused by its cap rather than truncating silently. Read referenced task pages by digest only (step 5). Follow related `[[Projects/…]]` / `[[Tasks/…]]` links from Overview and Current Plan the same way: `brain digest <linked page>`, never the body.

## Loading General Context ("load brain")

Read `pages/Index.md` and `pages/Meta.md` (both small). Present active projects, cross-project decisions and preferences. `brain activity "loaded brain overview"`.

## Searching ("what do we know about X")

Follow `references/search.md`. Afterwards: `brain activity 'searched "X" · N hits'`.

## Important Notes

- Never Read a whole page. Every partial read states its coverage; the helper's `coverage:` line is that statement.
- Never recompute a figure the helper printed.
- All graph content is Logseq outliner format; see `CLAUDE.md` for the invariants.
