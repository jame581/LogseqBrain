---
name: brain-save
description: >
  Save session context, decisions, progress, and plans to the Claude Brain Logseq
  graph. Triggers: "save to brain", "save this", "remember this", "store this
  decision", "log this", "save progress", "before I quit", "wrap up". Don't fire
  for read operations (use brain-load) or status checks (use brain-status).
---

# Brain Save

Persist session context — decisions, progress, plans, implementation details — to the Claude Brain Logseq graph for cross-session and cross-device continuity. Mechanical steps run through the helper; see `skills/_shared/run-brain.md`.

## Prerequisites

Run `brain info` once, and use its `graph:` path for every Read, Edit and Write this skill makes. If it exits 2, follow `skills/_shared/path-resolution.md`, then pass `--graph` to every call.

## What to Save

Six categories. `references/categories.md` gives each one's format:

1. Session Log Entry (always)
2. Decisions (when made; `references/decisions.md` covers conflicts and cross-project decisions)
3. Plan Updates (replace, don't append)
4. Implementation Details (when significant)
5. Jira Task Context (pointers, not full plans)
6. User Preferences & Meta (update `pages/Meta.md`)

## Save Process

1. **Identify target project(s)** from the project names, files and repos discussed, or the user's own words. If there are several, save to each. If it's unclear, ask: "This touched [X] and [Y] — save to both?"

2. **Verify the page exists.** If `brain sections` (step 3) exits 2 with `page not found`, tell the user and offer to create the page via `brain-init`'s "Adding a New Project". If they decline, list the available projects (`brain status`) and let them pick. Never write session data to a non-existent page.

   **Task pages** (`pages/Tasks___<ID>.md`): the page-top block must hold `status::` with one of `active | blocked | done`. Seed `status:: active` if it's missing. When the session signals completion ("merged", "deployed", "closed", "released", "hotovo"), **suggest** `status:: done`; never write a status change the user didn't confirm. If a worked task has no page, keep only the Current Plan pointer and offer to create the page. Never create it uninvited.

3. **Baseline, then read only what you'll touch.** One call, naming every file this save may write:
   ```
   brain sections <page> --baseline pages/Index.md journals/<yyyy_MM_dd>.md [pages/Meta.md] [pages/Decisions.md]
   ```
   It prints the section map and records the baselines that `brain check` diffs against. Then read only the sections you'll edit, with enough surrounding text for a unique Edit anchor and a duplicate check:
   - `brain tail <page> "Session Log" --entries 1 --max 4096`
   - `brain read <page> "Current Plan"`
   - `brain read <page> Decisions`, only when a decision was made (the conflict check in `references/decisions.md`)

4. **Compose the updates** per `references/categories.md`, following the content invariants in `skills/_shared/logseq-format.md`:
   - backticks for code, never `{{ }}`
   - no `#` directly before a number or word, **including after a letter** (`C#-parity`, `PKCS#12`); backtick the token or rephrase
   - namespaced `[[Tasks/…]]` / `[[Projects/…]]` links
   - markdown links for file paths, never `[[file://…]]`, and never relative `[x](docs/x.md)` links
   - Jira drafts fenced, verbatim

   Also run the decision-detection scan in `references/decisions.md` on your summary.

5. **Write with Edit, surgically.** Never rewrite a whole page. Account for Logseq's normalization first (`skills/_shared/logseq-format.md`):
   - append to Session Log
   - append to Decisions (with the conflict check)
   - replace Current Plan if it changed
   - update Implementation if needed
   - set `last-updated::` to today
   - seed or update a task page's `status::` (step 2)

   **Rotation check:** if step 3's page total exceeds 64 KB or Session Log holds more than 40 entries, suggest rotation per `references/rotation.md`. Suggestion only.

6. **Journal `## Sessions`:** append `- [[Projects/<Name>]]: <brief summary>` under `## Sessions` in today's `journals/yyyy_MM_dd.md`, at the end of the section. If the journal doesn't exist yet, create it with Write as `- ## Sessions` plus the bullet (and `mkdir -p journals` first if needed). If it exists without `## Sessions`, add the heading first.

7. **`pages/Meta.md`**, if new preferences emerged (`references/categories.md` category 6).

8. **Refresh the digest** (`skills/_shared/digest.md`). This runs unconditionally on every save:
   1. **Edit the page-top properties:** `focus::` and `next::` (required), `open::` only when something is genuinely open (otherwise remove the line), and `digest-updated::` set to today. Each value is one line of at most 120 bytes.
   2. **Edit the `## Digest` prose slots** from this session's knowledge, in slot order: Identity, Now, Binding, Hazard, then the free slot. Task pages usually need only Identity and Now. If the page has no `## Digest`, create it right after the property block, before the first `## ` heading. **Leave the Map line alone, or absent.**
   3. **`brain digest <page> --apply`.** It writes the Map from measurement and reports the caps:
      - `digest prose over cap by N B`: shorten the free slot first, then Binding and Hazard, and rerun.
      - `over: open:: … B > 120 B`: shorten that property and rerun.
      - A page with no digest before this save has just been backfilled lazily. Say so in step 11, and mention that a Rebuild from source is available.

9. **`pages/Index.md`:** every save rewrites this project's one-liner, as one single-line Edit.
   - Keep the stable descriptor before the parenthetical untouched.
   - Replace the parenthetical with `(<latest version or milestone> — <current focus>)`, e.g. `(v0.8.0 shipped 2026-06-23 — v0.9.0 in design)`. If the one-liner has no parenthetical yet, append one.
   - This is unconditional: Index rot comes from "only when status changed" judgment calls.
   - If the project is missing from `pages/Index.md`, add a one-liner under `## Projects`, with the descriptor taken from the page's first Overview bullet.

10. **`brain check <page> pages/Index.md journals/<yyyy_MM_dd>.md`**, plus Meta and Decisions if you wrote them.
    - **error**: a mechanical violation on a line this save wrote. Fix it with Edit, then re-run `check` on that file.
    - **warn** (`broken-link`, `new-property-key`): tell the user; don't block on it. For example: "linked `Tasks/CRMGM-2070`, which has no page yet".

11. **`brain activity "saved [[Projects/<Name>]]"`**, then **confirm** in plain language what was written, including the check result and any warn-tier items.

## Auto-Suggest Save

See `references/auto-suggest.md`. Suggestion only; never auto-save.

## Important Notes

- Edit for surgical updates only; never rewrite a whole page (Sync conflicts). New entries go at the end of their section, before the next `## ` heading.
- **Call `brain sections` once per save, before the first Edit.** Calling it again resets the baselines `brain check` diffs against. Later measurements come from `brain digest`, `read` and `tail`, which don't touch baselines. A rotation the user accepts runs after step 10's check.
- Never hand-edit the Map line, and never compute a byte figure yourself.
- All content is bullets. See `CLAUDE.md` for the Logseq invariants.
