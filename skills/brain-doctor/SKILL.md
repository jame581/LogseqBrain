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

Scan the whole graph for the format mistakes that silently corrupt a Logseq graph — inline code wrapped in `{{ }}` (broken macros), bare `#number`/hex tags and un-namespaced `[[links]]` (phantom empty pages), `[[file://]]` links, and junk/description links — plus data-quality checks — malformed properties, broken/duplicate entries, and missing-structure gaps (see the full catalog in `skills/_shared/hygiene-rules.md`) — then report them and, on confirmation, repair them. This is a maintenance tool: run it on demand, not as part of the save/load cycle.

See `skills/_shared/hygiene-rules.md` for the full catalog: each rule with its detection pattern, auto-fixable tier, and remediation. The compose-time rules these checks enforce live in `skills/_shared/logseq-format.md`.

## Modes

- **Report** (default, "lint brain" / "check brain health" / "why are there empty pages"): detect and summarize, change nothing.
- **Fix** ("fix brain" / "clean up brain" / explicit "yes, fix them" after a report): repair after a backup, with the user's confirmation.

If the trigger is ambiguous, run **Report** first and offer to fix.

## Prerequisites

Resolve the graph path per `skills/_shared/path-resolution.md`.

## Process

1. **Scan.** For each rule in `skills/_shared/hygiene-rules.md` with `enforced-at: scan` (all 9), run its detection across `pages/` and `journals/`. Collect counts and 1–2 example locations per rule. Stay read-only in this phase.

2. **Report.** Present a compact health summary grouped by the rule's `auto-fixable` field:
   - **Auto-fixable** (`yes` / `safe-only`): `code-in-braces`, `bare-hash-tag`, `unnamespaced-link`, `file-link`, `malformed-property` (safe tiers only).
   - **Needs your call** (`report`): `description-link`, `broken-link` (with suggested matches), `duplicate-entry` (the duplicate groups), `structural-integrity` (missing props / stub sections).
   Example:
   ```
   Brain health: 12 issues across 6 pages
   Auto-fixable (5):  3 {{code}}, 1 bare #tag, 1 malformed property
   Needs your call (7): 2 broken links (1 likely typo → suggests [[Tasks/CRMGM-1982]]),
                        3 duplicate Session Log entries, 2 pages missing last-updated::
   ```
   If the graph is clean, say so and stop — no backup, journey-log just `ran brain-doctor (clean)`.

3. **Confirm before any write.** Never repair without explicit user confirmation — consistent with the plugin's "never persist without confirmation" rule. Ask which classes to fix if the user hasn't said.

4. **Back up first.** The graph is usually **not** git-tracked, so there is no undo. Before the first edit, copy `pages/`, `journals/`, and `logseq/` to a timestamped backup folder (e.g. `<graph>/.brain-doctor-backup-<yyyy-MM-dd-HHmm>/` or the host scratchpad). Tell the user where it is. If the backup fails, stop — do not edit.

5. **Repair.** Apply per `auto-fixable`:
   - **Auto-fixable group:** on one confirmation, apply the remediation from `skills/_shared/hygiene-rules.md`. For high-volume mechanical classes (`code-in-braces`, `bare-hash-tag`) a single scripted pass over the affected files is appropriate — this is one-time maintenance, not the per-session surgical save path, and a backup was taken. For `malformed-property`, apply only the safe tiers (page-top block; inline keys confirmed as `::` elsewhere). Hand-fix the brace/backtick edge cases noted in the catalog.
   - **Needs-your-call group:** walk each finding with the user (per-item or batch), applying only what they approve. Never auto-write `broken-link`, `duplicate-entry`, or `structural-integrity` changes.

6. **Verify.** Re-run the detections. Confirm zero remaining (excluding intentional forward-references the user chose to keep) and that backtick counts per file are even (no broken inline-code spans).

7. **Report results and write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `ran brain-doctor · fixed <N> issues` (or `ran brain-doctor (clean)`).

## Important Notes

- **Report before repair, backup before write, confirm before both.** A graph is the user's long-term memory; never mutate it silently.
- **A link to a missing page is not always a bug.** Users legitimately reference tickets/pages that don't exist yet. Surface these but default to leaving them unless the user says otherwise.
- **Logseq may be running.** Recommend the user close Logseq (or pause Sync) during a bulk fix to avoid mid-write sync conflicts.
- **Prevention beats cure.** When you finish, remind the user that `brain-save` now follows the compose-time invariants (`skills/_shared/logseq-format.md`), so a freshly maintained graph should stay clean.
