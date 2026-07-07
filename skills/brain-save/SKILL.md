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

   **Task pages:** a save may also target a task page (`pages/Tasks___<ID>.md`) when the session was about that task. Task pages have no fixed template, but their page-top property block must contain `status::` with one of `active | blocked | done`. If the page exists without `status::`, seed `status:: active` as part of this save. If the session content signals completion ("merged", "deployed", "closed", "released", "hotovo"), **suggest** `status:: done` — never write a status change the user didn't confirm (same rule as auto-save).

3. **Read the current project page selectively** using the section-targeted-read pattern in `skills/_shared/section-locator.md`. Read only the sections you'll touch (Session Log, Decisions, Current Plan, Implementation) — never the whole file. The read serves two purposes: detect duplicates before appending, and provide enough surrounding lines for the Edit `old_string` to be unique.

4. **Prepare the updates** for each applicable category from `references/categories.md`. When composing the text, follow the **content-generation invariants** in `skills/_shared/logseq-format.md` — backticks for code (never `{{ }}`), escape `#` before numbers/hex, namespace every `[[Tasks/…]]` / `[[Projects/…]]` link, and use markdown links (not `[[file://]]`) for file paths. Violating these silently spawns phantom pages and broken macros.

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

9. **Refresh `pages/Index.md`.** Every save rewrites the saved project's one-liner: keep the stable descriptor before the parenthetical untouched; replace the parenthetical with `(<latest version or milestone> — <current focus>)`, e.g. `(v0.8.0 shipped 2026-06-23 — v0.9.0 in design)`. One surgical single-line Edit. This is unconditional — Index rot comes precisely from "only when status changed" judgment calls.

10. **Post-write verify.** Run the "Post-write verify (scoped)" procedure in `skills/_shared/hygiene-rules.md` over exactly the files written in steps 6–9. Fix any hit per the catalog remediation and re-verify. This is mandatory — the compose self-check (step 5) is necessary but not sufficient.

11. **Write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `saved [[Projects/<ProjectName>]]`.

12. **Confirm to the user** in plain language what was saved. List each thing written.

## Auto-Suggest Save

See `references/auto-suggest.md`. Suggestion only — never auto-save.

## Important Notes

- Edit tool for surgical updates only. Never rewrite a whole page (sync conflicts).
- All content in bullet-point format. See `CLAUDE.md` for Logseq invariants.
- When appending, place new entries at the end of the section, before the next `##` heading.
- If `journals/` doesn't exist, create it (Bash `mkdir -p`) before writing the journal entry.
