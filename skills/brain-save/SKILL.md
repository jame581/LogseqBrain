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

3. **Read the current project page selectively.** Don't read the whole file — for each section you need to update or check (Session Log, Decisions, Current Plan, Implementation):

   1. Run Grep with `output_mode: "content"`, `-n: true`, pattern `^- ## (Session Log|Decisions|Current Plan|Implementation)` against the project file. This returns the line number of each section heading.
   2. For each section you need: Read with offset = section line, limit = (next-section-line - section-line) or ~50 lines if it's the last section.
   3. Use the section content to (a) detect duplicates before appending, (b) anchor the Edit `old_string` with enough context to be unique.

   For very large project pages (1000+ lines), this avoids reading 1000 lines just to append 5.

4. **Prepare the updates** for each applicable category from `references/categories.md`.

5. **Write the updates** using the Edit tool — surgical updates per section, never rewrite the whole page:
   - Append to Session Log
   - Append to Decisions (with conflict check per `references/decisions.md`)
   - Replace Current Plan if changed
   - Update Implementation if needed
   - Update `last-updated::` to today's date

6. **Update the journal — `## Sessions`.** Append a rich cross-reference to today's `journals/yyyy_MM_dd.md`:

   ```markdown
   - ## Sessions
     - [[Projects/ProjectName]]: Brief summary of session
   ```

7. **Update `pages/Meta.md`** if new user preferences emerged (see `references/categories.md` category 6).

8. **Update `pages/Index.md`** if a project status changed or new cross-project info emerged.

9. **Write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `saved [[Projects/<ProjectName>]]`.

10. **Confirm to the user** in plain language what was saved. List each thing written.

## Auto-Suggest Save

See `references/auto-suggest.md`. Suggestion only — never auto-save.

## Important Notes

- Edit tool for surgical updates only. Never rewrite a whole page (sync conflicts).
- All content in bullet-point format. See `CLAUDE.md` for Logseq invariants.
- When appending, place new entries at the end of the section, before the next `##` heading.
- If `journals/` doesn't exist, create it (Bash `mkdir -p`) before writing the journal entry.
