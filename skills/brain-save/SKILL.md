---
name: brain-save
description: >
  Save session context, decisions, progress, and plans to the Claude Brain Logseq
  graph. Triggers: "save to brain", "save this", "remember this", "store this
  decision", "log this", "save progress", "before I quit", "wrap up". Don't fire
  for read operations (use brain-load) or status checks (use brain-status).
---

# Brain Save

Persist session context — decisions, progress, plans, implementation details — to the Claude Brain Logseq graph for cross-session and cross-device continuity.

## Prerequisites

Resolve the graph path per `skills/_shared/path-resolution.md`.

## What to Save

Six categories — see `references/categories.md` for each one's format and rules. The orchestrator decides which apply based on what the session covered:

1. Session Log Entry (always)
2. Decisions (when made — see `references/decisions.md` for conflict + cross-project rules)
3. Plan Updates (when plans changed — replace, don't append)
4. Implementation Details (when significant)
5. Jira Task Context (when tasks were worked on — store pointers, not full plans)
6. User Preferences & Meta (when newly discovered — update `pages/Meta.md`)

## Save Process

1. **Identify target project(s).** Look for project names mentioned, files/repos discussed, or explicit user statements ("we're working on X"). If multiple projects, save to each. If unclear, ask: "This touched [X] and [Y] — save to both?"

2. **Verify project page exists.** Glob for `pages/Projects___<ProjectName>.md`. If missing:
   - Tell user: "No project page found for [name]. Want me to create one first?"
   - If yes, hand off to `brain-init` "Adding a New Project" flow, then continue.
   - If no, list available projects and let the user pick.
   - Never write session data to a non-existent project page.

   **Task pages:** a save may also target a task page (`pages/Tasks___<ID>.md`) when the session was about that task. Task pages have no fixed template, but their page-top property block must contain `status::` with one of `active | blocked | done`. If the page exists without `status::`, seed `status:: active` as part of this save. If the session content signals completion ("merged", "deployed", "closed", "released", "hotovo"), **suggest** `status:: done` — never write a status change the user didn't confirm (same rule as auto-save). If no task page exists for a worked task, keep the Current Plan pointer entry only — don't create `Tasks___<ID>.md` uninvited; offer to create one and only do so if the user wants it.

3. **Read the current project page selectively** using the section-targeted-read pattern in `skills/_shared/section-locator.md`. Read only the sections you'll touch (Session Log, Decisions, Current Plan, Implementation) — never the whole file. The read serves two purposes: detect duplicates before appending, and provide enough surrounding lines for the Edit `old_string` to be unique.

4. **Prepare the updates** for each applicable category from `references/categories.md`. When composing the text, follow the **content-generation invariants** in `skills/_shared/logseq-format.md` — backticks for code (never `{{ }}`), escape `#` before numbers/hex, namespace every `[[Tasks/…]]` / `[[Projects/…]]` link, and use markdown links (not `[[file://]]`) for file paths. Violating these silently spawns phantom pages and broken macros. Also run the decision-detection scan on your composed session summary per the "Decision detection (forward-only)" section of `references/decisions.md`.

5. **Self-check the composed text** against `skills/_shared/hygiene-rules.md` before writing — the rules with `enforced-at: compose` and `auto-fixable` of `yes`/`safe-only`: `code-in-braces`, `bare-hash-tag`, `unnamespaced-link`, `file-link`, `malformed-property`. Scan only the block(s) you just composed (pure in-memory; no extra file reads), and silently correct any violation to the invariant form — it's your own output, so no prompt. For `malformed-property` specifically, only auto-correct `key:` → `key::` when the composed block is a page-top property block (e.g. updating `last-updated::`); in a section append such as Session Log or Decisions a `key: value` line may be prose, so leave it for `brain-doctor` to report. Do **not** run the `report` rules (`broken-link`, `duplicate-entry`, `structural-integrity`, `description-link`); those need whole-graph context and belong to `brain-doctor`. Contract: never emit a mechanical violation.

6. **Write the updates** using the Edit tool — surgical updates per section, never rewrite the whole page:

   > Before any Edit, account for Logseq's parse-time normalization (dropped `- ` on headings, space→tab indents, stripped empty headings). Confirm the region's current normalized form before editing and anchor on heading text — see `skills/_shared/logseq-format.md`.

   - Append to Session Log
   - Append to Decisions (with conflict check per `references/decisions.md`)
   - Replace Current Plan if changed
   - Update Implementation if needed
   - Update `last-updated::` to today's date
   - Seed/update the task page's page-top `status::` when the save targets a task page (per step 2 — seed `active` if missing; write `done`/`blocked` only with the user's confirmation)
   - After appending to Session Log, check the rotation trigger per `references/rotation.md` (64 KB / 40 entries) and suggest rotation if exceeded — suggestion only.

7. **Update the journal — `## Sessions`.** Append a rich cross-reference to today's `journals/yyyy_MM_dd.md`:

   ```markdown
   - ## Sessions
     - [[Projects/ProjectName]]: Brief summary of session
   ```

8. **Update `pages/Meta.md`** if new user preferences emerged (see `references/categories.md` category 6).

9. **Refresh the digest.** Unconditional on every save — the same discipline as the Index one-liner below, and for the same reason: rot comes precisely from "only when it changed" judgment calls. Follow `skills/_shared/digest.md`:
   1. **Recompute the Map from the page's real section map** — the derivation shell in `skills/_shared/digest.md`: enumerate the page's actual `## ` sections, measure each, keep the ones at or above the 1 KB threshold, largest first, annotating `Session Log`/`Decisions` with their dated-entry counts when they clear it. This is not a fixed field list — a page whose real second-largest section is `## Active Tasks` gets `Active Tasks` in the Map, not just the sections a template happened to name. Byte figures are authoritative; when a session-entry or decision count comes back 0 **or comes back lower than the section's own top-level child-bullet count**, omit the count rather than writing `0 entries`/`(0)` or a number already known to be a floor. Labels longer than 40 characters are truncated (`…` marker, diff key preserved) and joined to their figure with the reserved ` | ` separator — never key two different labels to the same truncated string. Sections that never clear the 1 KB threshold are summarized in one reconciling `+N smaller sections, X KB` clause, not omitted outright, so the Map's figures account for the whole page. All of this is specified once in `skills/_shared/digest.md` — follow it there, not a paraphrase here.
   2. **Rewrite the page-top properties** `focus::`, `next::`, and `digest-updated::` (today). Write `open::` only when something is genuinely open — otherwise remove the line entirely. Each value is **one line, ≤ 120 bytes** — the same `oversized-digest` rule caps properties as well as the section.
   3. **Rewrite the `## Digest` bullets** from the same session knowledge that produced the Session Log entry and the Current Plan, in slot order: Identity, Now, Binding, Hazard, free, Map.
   4. **Check the 800-byte cap before writing** (`oversized-digest`, compose tier — `skills/_shared/hygiene-rules.md`). The Map's own fitting rule (`skills/_shared/digest.md` "Fitting the 800-byte cap") reserves room for `+N more`, the reconciling residual, the `Archive` pointer, and the page total *before* accepting a candidate, so this recompression path is now the rare case — a fitting bug once let a Map reach 808 B by discovering those costs only after the fact. Still over cap → recompress: shrink the Map first (drop its smallest above-threshold candidates, append `+N more`), then the free slot, then shorten Binding and Hazard. Never drop the Map wholesale.
   5. **Write the two surgical Edits** — one on the page-top property block, one on the `## Digest` section (creating it, if absent, immediately after the property block and before the page's first `## ` section — `## Overview` on project pages; task pages have no fixed template, so it's simply whichever heading comes first).
   6. **Re-measure the page and correct `page` if it changed.** The Edits in step 5 change the file's own byte count, so the `page` figure computed in step 1 (before those Edits) can already be stale the instant it lands — on a large page this can cross a KB boundary (measured live: a pre-write `page 106 KB` against a 109,786 B post-write file, which is 107 KB). `wc -c` the file again; if the rounded figure differs from what step 1 computed, Edit just that bullet to correct it. One extra `wc -c` and at most a one-character digit swap — see `skills/_shared/digest.md`'s "second pass" step. No other Map figure needs this: they measure sections these Edits don't touch.
   7. **If the page has no digest yet**, build one now from what is already in context — this is the lazy backfill path. Say so in the step-13 confirmation and mention that a full rebuild-from-source is available for richer history.
   8. **Task pages get a digest too**, thinner: Identity + Now + Map.

10. **Refresh `pages/Index.md`.** Every save rewrites the saved project's one-liner: keep the stable descriptor before the parenthetical untouched; replace the parenthetical with `(<latest version or milestone> — <current focus>)`, e.g. `(v0.8.0 shipped 2026-06-23 — v0.9.0 in design)`. One surgical single-line Edit. This is unconditional — Index rot comes precisely from "only when status changed" judgment calls. If the project's one-liner has no parenthetical yet, append one after the stable descriptor. If the project is missing from `pages/Index.md` entirely, add a one-liner under `## Projects` — descriptor taken from the project page's first Overview bullet, then the parenthetical.

11. **Post-write verify.** Run the "Post-write verify (scoped)" procedure in `skills/_shared/hygiene-rules.md` over exactly the files written in steps 6–10. Fix any hit per the catalog remediation and re-verify. This is mandatory — the compose self-check (step 5) is necessary but not sufficient.

12. **Write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `saved [[Projects/<ProjectName>]]`.

13. **Confirm to the user** in plain language what was saved. List each thing written.

## Auto-Suggest Save

See `references/auto-suggest.md`. Suggestion only — never auto-save.

## Important Notes

- Edit tool for surgical updates only. Never rewrite a whole page (sync conflicts).
- All content in bullet-point format. See `CLAUDE.md` for Logseq invariants.
- When appending, place new entries at the end of the section, before the next `##` heading.
- If `journals/` doesn't exist, create it (Bash `mkdir -p`) before writing the journal entry.
