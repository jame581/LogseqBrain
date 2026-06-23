---
name: brain-doctor
description: >
  Lint and repair the Claude Brain Logseq graph — find and fix format
  violations that create phantom pages or broken macros. Triggers: "brain
  doctor", "lint brain", "check brain health", "clean up brain", "fix brain",
  "graph hygiene", "why are there empty pages", "find broken pages". Don't fire
  for loads (use brain-load), saves (use brain-save), status/analytics (use
  brain-status), or first-time setup (use brain-init).
---

# Brain Doctor

Scan the whole graph for the format mistakes that silently corrupt a Logseq graph — inline code wrapped in `{{ }}` (broken macros), bare `#number`/hex tags and un-namespaced `[[links]]` (phantom empty pages), `[[file://]]` links, and junk/description links — then report them and, on confirmation, repair them. This is a maintenance tool: run it on demand, not as part of the save/load cycle.

See `references/checks.md` for the full catalog: each issue class with its detection pattern and remediation. The compose-time rules these checks enforce live in `skills/_shared/logseq-format.md`.

## Modes

- **Report** (default, "lint brain" / "check brain health" / "why are there empty pages"): detect and summarize, change nothing.
- **Fix** ("fix brain" / "clean up brain" / explicit "yes, fix them" after a report): repair after a backup, with the user's confirmation.

If the trigger is ambiguous, run **Report** first and offer to fix.

## Prerequisites

Resolve the graph path per `skills/_shared/path-resolution.md`.

## Process

1. **Scan.** For each issue class in `references/checks.md`, run its detection (a single Grep or Bash `grep` across `pages/` and `journals/`). Collect counts and a few example locations per class. Stay read-only in this phase.

2. **Report.** Present a compact summary grouped by issue class — count, what it breaks (phantom page / broken macro), and 1–2 examples. Distinguish **auto-fixable** classes from **needs-judgment** ones:
   - Auto-fixable: `{{code}}`→backticks, `#number`/hex→backticks, bare `[[Task]]`→`[[Tasks/Task]]`, `[[file://]]`→markdown link.
   - Needs judgment: links to *missing* pages (could be a real forward-reference the user wants to keep, or a typo), and description/slug links.
   If the graph is clean, say so and stop — no backup, no journey-log churn beyond a single `ran brain-doctor (clean)` line.

3. **Confirm before any write.** Never repair without explicit user confirmation — consistent with the plugin's "never persist without confirmation" rule. Ask which classes to fix if the user hasn't said.

4. **Back up first.** The graph is usually **not** git-tracked, so there is no undo. Before the first edit, copy `pages/`, `journals/`, and `logseq/` to a timestamped backup folder (e.g. `<graph>/.brain-doctor-backup-<yyyy-MM-dd-HHmm>/` or the host scratchpad). Tell the user where it is. If the backup fails, stop — do not edit.

5. **Repair.** Apply each confirmed class's remediation from `references/checks.md`. For the high-volume, mechanical classes (`{{code}}`, `#number`) a single scripted pass over the affected files is appropriate — this is a one-time maintenance operation, not the per-session surgical save path, so a bulk transform with a backup is the right tool. Hand-fix the few edge cases the bulk pass can't safely handle (spans containing literal braces or backticks — see `references/checks.md`).

6. **Verify.** Re-run the detections. Confirm zero remaining (excluding intentional forward-references the user chose to keep) and that backtick counts per file are even (no broken inline-code spans).

7. **Report results and write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `ran brain-doctor · fixed <N> issues` (or `ran brain-doctor (clean)`).

## Important Notes

- **Report before repair, backup before write, confirm before both.** A graph is the user's long-term memory; never mutate it silently.
- **A link to a missing page is not always a bug.** Users legitimately reference tickets/pages that don't exist yet. Surface these but default to leaving them unless the user says otherwise.
- **Logseq may be running.** Recommend the user close Logseq (or pause Sync) during a bulk fix to avoid mid-write sync conflicts.
- **Prevention beats cure.** When you finish, remind the user that `brain-save` now follows the compose-time invariants (`skills/_shared/logseq-format.md`), so a freshly maintained graph should stay clean.
