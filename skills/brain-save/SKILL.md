---
name: brain-save
description: >
  Save session context, decisions, progress, and plans to the Claude Brain Logseq
  graph. Triggers: "save to brain", "save this", "remember this", "store this
  decision", "log this", "save progress", "before I quit", "wrap up". Don't fire
  for read operations (use brain-load) or status checks (use brain-status).
---

# Brain Save

Persist session context to the Claude Brain Logseq graph, for continuity across sessions and devices. A routine save is: `save-begin`, one Read, three Edits, `save-finish`. It reads no file but this one.

## Running the helper

- Bash: `sh "<this skill's base directory>/../_shared/bin/brain" <command> …`
- PowerShell-only Windows: `& "$(Split-Path (Split-Path (Get-Command git).Source))\bin\bash.exe" "<base>/../_shared/bin/brain" <command> …`
- Neither works: stop and say *"logseq-brain needs Git for Windows (Git Bash) — https://git-scm.com/download/win"*.
- In Cowork, always pass `--graph <connected folder>`. Elsewhere pass `--graph` only when the graph is not configured. It may go anywhere on the line. On exit 2 with `graph not resolved`, follow `skills/_shared/path-resolution.md`, then pass `--graph`.
- Put text arguments in single quotes; a `'` inside becomes `'\''`. In double quotes the shell runs backticks and expands `$`.
- Exit 0 clean, 1 findings (act on them), 2 error (act on its reason; don't retry blindly). Quote every `coverage:` line. Never recompute a figure it printed. Its `graph:` line is the folder for your own Reads and Edits.

## Save process

1. **Targets.** Take the project from the names, files and repos discussed, or the user's words. If unclear, ask: "This touched [X] and [Y] — save to both?" Several pages are saved **one at a time**, each running steps 2–7 before the next begins.

2. **`brain save-begin <page> [--also FILE…]`.** Don't list the graph first. It baselines the page, `pages/Index.md` and today's journal, and prints what you edit:
   - `== digest`: the property block and `## Digest`;
   - `== session-log`: the newest entry;
   - `== current-plan`;
   - `== anchors`: the page's Index line and the end of today's `## Sessions`.

   Name every other file this save may write with `--also`: `pages/Meta.md`, `pages/Decisions.md`, `pages/Tasks___<ID>.md`. If the need appears while composing, rerun `save-begin` with the full list **before the first Edit**, never after: a rerun resets the baselines.
   - **`page not found`** (exit 2): never write to a missing page. Offer to create it via brain-init's "Adding a New Project". If declined, list the projects (`brain status`) and let the user pick.
   - **Task pages:** the page-top block must hold `status::` with `active | blocked | done`. Seed `status:: active` if it's missing. On completion signals ("merged", "deployed", "closed", "released", "hotovo"), **suggest** `status:: done`, and never write a status change the user didn't confirm. Read or edit a task page only to change its `status::`, passing it in `--also`. A worked task with no page gets only the Current Plan pointer and an offer to create it. Never create one uninvited.

3. **One Read of the page, for Edit:** `Read` with `offset: 1, limit: 1`. That unlocks Edit for the whole file. The text you replace comes from step 2's output. Need another section's text for an anchor (Implementation, Decisions)? Use `brain read <page> '<section>'`, not a whole-page Read. Don't read Index or the journal: `save-finish` writes them.

4. **Compose.**
   - **Session Log entry** (always), appended after the newest entry:
     ```
       - yyyy-MM-dd: Brief summary of what was done
         - Detail
         - files-modified:: key files changed
         - skills-used:: skills or tools used
         - related-tickets:: Jira IDs
         - open-questions:: unresolved questions to carry forward
     ```
     Write each `::` child only when it has a real value.
   - **Current Plan:** replace it when the plan changed; there is exactly one plan. For a Jira task, keep a **pointer** only: `- PROJ-1234: title` with `status::`, `estimate::`, `task-folder::` and `summary::` children. Add the ID to `related-tickets::`. The full plan lives in the task folder.
   - **Implementation:** append only notes that will matter in future sessions.
   - **Meta** (`pages/Meta.md`, in `--also`): only new, lasting preferences, conventions or tools. Never one-off instructions or sensitive data. Details in `references/categories.md` § 6.
   - **Decisions, detected on every save:** scan your composed text for decision-shaped statements ("decided", "chose X over Y", "went with", "will use", "instead of", "superseded", "rozhodnuto", "zvolili jsme"). Ask once, as a batch: *"These N statements look like decisions — record them in Decisions? (1) … (2) …"* Record only approved ones, and for those read `references/decisions.md` (the conflict check and the cross-project copy to `pages/Decisions.md`, which must then be in `--also`). Declined ones stay as Session Log prose.
   - **Invariants.** Self-check every line against these before any Edit, and correct silently. Logseq parses a file as soon as it changes and never deletes a page it created, so a bad line fixed seconds later can still leave a phantom page.
     - Backticks for code, never `{{ }}`.
     - No `#` directly before a number or word, **even after a letter** (`C#-parity`, `PKCS#12`): backtick the token or rephrase.
     - Links to projects and tasks are namespaced: `[[Tasks/…]]`, `[[Projects/…]]`.
     - File paths are markdown links `[x](file:///…)` or backticks. Never `[[file://…]]`, never relative `[x](docs/x.md)`.
     - Jira drafts go verbatim in fenced blocks.
     - `key::` only in the page-top block. In a Session Log line, `- status: blocked` is prose.
     - Everything is a bullet; dates are `yyyy-MM-dd`.

5. **Edit the page surgically.** Never rewrite a whole page. New entries go at the end of their section.
   - **One Edit for the properties and `## Digest` prose** (they are adjacent). Set `last-updated::` and `digest-updated::` to today. Write `focus::` and `next::` (both required). Write `open::` only when something is genuinely open; otherwise remove the line. Each value is one line of at most 120 bytes. Rewrite the prose bullets from this session's knowledge, in slot order: Identity, Now, Binding (dated pointers to decisions), Hazard, then a free slot. Task pages usually need only Identity and Now. The whole section is capped at 800 B, Map included. **Leave the Map line alone**; `save-finish` computes it. A page with no `## Digest` gets one here, right after the property block, per `skills/_shared/digest.md` § Surface 2. Say in step 7 that it was backfilled, and that a Rebuild from source is available.
   - Current Plan (replace), then Session Log (append).
   - Implementation, Decisions, Meta, and a task page's `status::`, when needed.
   - If an Edit anchor doesn't match, Logseq normalized the file: see `skills/_shared/logseq-format.md`.
   - **Rotation:** if step 2's table shows a page total over 64 KB, or a Session Log over 40 entries, suggest rotation per `references/rotation.md`. It is a suggestion only, and it runs after step 6.

6. **`brain save-finish <page> --summary '<one line>' --index '<latest version or milestone> — <current focus>'`.** Use single quotes. Pass `--index` for a project page only. The summary becomes `- [[Projects/<Name>]]: <summary>` under today's `## Sessions`. The index text replaces the parenthetical of the page's one-liner in `pages/Index.md` (e.g. `v0.8.0 shipped 2026-06-23 — v0.9.0 in design`). Both are rewritten on every save. The command validates, writes the Sessions bullet, the Index text and the Map, checks every file `save-begin` baselined, and logs the activity line.
   - **A refusal** (text, cap or Map; exit 1 or 2) wrote nothing. Fix the cause, then rerun **the same command**. For `over:` lines, shorten the free slot first, then Binding and Hazard, with one Edit. A refused text gets rephrased.
   - **`index: missing`:** Read `pages/Index.md` and add the one-liner under `## Projects`, its descriptor taken from the page's first Overview bullet. Then run `brain check pages/Index.md`. **`index: ambiguous`:** tell the user.
   - **`check …` error-tier findings:** a line this save wrote breaks a rule, and the activity line is deferred. The helper has written the Map, so Read the page again before fixing with Edit. Then run the `brain check … && brain activity …` it printed.
   - **Warn-tier** (`broken-link`, `new-property-key`): tell the user; don't block. For example: "linked `Tasks/CRMGM-2070`, which has no page yet".
   - **`nonconvergent-map` / `duplicate-map`:** see `skills/_shared/hygiene-rules.md`.

7. **Confirm** in plain language: what was written, the check result, any warn-tier items, and a digest backfill if one happened.

## Auto-suggest

See `references/auto-suggest.md`. Suggest only; never auto-save.

## Important notes

- Run `save-begin` once per page, before its first Edit. A rerun resets the baselines `save-finish` checks against.
- Never hand-edit the Map line, and never compute a byte figure yourself.
- A rotation moves Session Log entries verbatim. A finding its `brain check` reports on the archive page is carried-over content: report it and leave it for brain-doctor.
