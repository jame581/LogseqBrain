---
name: brain-doctor
description: >
  Lint and repair the Claude Brain Logseq graph — find and fix format
  violations that create phantom pages or broken macros. Triggers: "brain
  doctor", "lint brain", "check brain health", "clean up brain", "fix brain",
  "graph hygiene", "why are there empty pages", "find broken pages",
  "backfill digests", "rebuild digest for <project>". Don't fire for loads
  (use brain-load), saves (use brain-save), status/analytics (use
  brain-status), or first-time setup (use brain-init).
---

# Brain Doctor

Scan the whole graph for the format mistakes that silently corrupt a Logseq graph — inline code wrapped in `{{ }}` (broken macros), bare `#number`/hex tags and un-namespaced `[[links]]` (phantom empty pages), `[[file://]]` links, junk/description links, and un-fenced Jira markup residue — plus data-quality checks — malformed properties, broken/duplicate entries, and missing-structure gaps (see the full catalog in `skills/_shared/hygiene-rules.md`) — then report them and, on confirmation, repair them. This is a maintenance tool: run it on demand, not as part of the save/load cycle.

See `skills/_shared/hygiene-rules.md` for the full catalog: each rule with its detection pattern, auto-fixable tier, and remediation. The compose-time rules these checks enforce live in `skills/_shared/logseq-format.md`.

## Modes

- **Report** (default, "lint brain" / "check brain health" / "why are there empty pages"): detect and summarize, change nothing.
- **Fix** ("fix brain" / "clean up brain" / explicit "yes, fix them" after a report): repair after a backup, with the user's confirmation.

If the trigger is ambiguous, run **Report** first and offer to fix.

## Prerequisites

Resolve the graph path per `skills/_shared/path-resolution.md`.

## Process

1. **Scan.** For each rule in `skills/_shared/hygiene-rules.md` with `enforced-at: scan` (all 14), run its detection across `pages/` and `journals/`. Collect counts and 1–2 example locations per rule. Stay read-only in this phase.

2. **Report.** Present a compact health summary grouped by the rule's `auto-fixable` field:
   - **Auto-fixable** (`yes` / `safe-only`): `code-in-braces`, `bare-hash-tag`, `unnamespaced-link`, `file-link`, `malformed-property` (safe tiers only).
   - **Needs your call** (`report`): `description-link`, `broken-link` (with suggested matches), `duplicate-entry` (the duplicate groups), `structural-integrity` (missing props / stub sections), `jira-markup` (unfenced Jira residue — suggests the fence wrap), `missing-digest` (pages with no digest, largest first), `stale-digest` (digest older than the page), `stale-map` (Map claims figures that no longer match the page's measured bytes), `oversized-digest` (digest over the 800 B cap — report only; never trim on-disk content automatically).
   Example:
   ```
   Brain health: 16 issues across 8 pages
   Auto-fixable (5):  3 {{code}}, 1 bare #tag, 1 malformed property
   Needs your call (7): 2 broken links (1 likely typo → suggests [[Tasks/CRMGM-1982]]),
                        3 duplicate Session Log entries, 2 pages missing last-updated::
   Digests (4):       4 pages with no digest (Fat 109 KB, …) — say "backfill digests"
   ```
   The headline total counts **every** bucket — 5 + 7 + 4 = 16. Digests are broken out for readability, never excluded from the count; a total that quietly omits a bucket is the same under-reporting this release exists to eliminate.
   If the graph is clean, say so and stop — no backup, journey-log just `ran brain-doctor (clean)`.

3. **Confirm before any write.** Never repair without explicit user confirmation — consistent with the plugin's "never persist without confirmation" rule. Ask which classes to fix if the user hasn't said.

4. **Back up first.** The graph is usually **not** git-tracked, so there is no undo. Before the first edit, copy `pages/`, `journals/`, and `logseq/` to a timestamped backup folder (e.g. `<graph>/.brain-doctor-backup-<yyyy-MM-dd-HHmm>/` or the host scratchpad). Tell the user where it is. If the backup fails, stop — do not edit.

5. **Repair.** Apply per `auto-fixable`:
   - **Auto-fixable group:** on one confirmation, apply the remediation from `skills/_shared/hygiene-rules.md`. For high-volume mechanical classes (`code-in-braces`, `bare-hash-tag`) a single scripted pass over the affected files is appropriate — this is one-time maintenance, not the per-session surgical save path, and a backup was taken. For `malformed-property`, auto-fix only the page-top property block; report inline `key: value` hits for user approval (an inline line may be prose). Hand-fix the brace/backtick edge cases noted in the catalog.
   - **Needs-your-call group:** walk each finding with the user (per-item or batch), applying only what they approve. Never auto-write `broken-link`, `duplicate-entry`, or `structural-integrity` changes.

6. **Verify.** Re-run the detections. Confirm zero remaining (excluding intentional forward-references the user chose to keep) and that backtick counts per file are even (no broken inline-code spans). Then, for every page whose bytes changed during repair, **Remap** its digest per `skills/_shared/digest.md` — recompute the Map bullet only, leaving `digest-updated::` and the prose slots untouched; a repair carries no session knowledge to refresh them from, so this is a Remap, not a Refresh (bumping `digest-updated::` would silence `stale-digest` for another 30 days on prose nobody touched). A repair is exactly the kind of byte-moving write that leaves a stale Map behind (see `stale-map`) if the digest isn't recomputed alongside it.

7. **Report results and write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `ran brain-doctor · fixed <N> issues` (or `ran brain-doctor (clean)`).

## Guided digest backfill

Triggered by "backfill digests" (or accepted from a `missing-digest` report). Same shape as the v0.9.0 task-status backfill: report, cost, one confirmation, then work.

1. **Report what is missing.** Run the `missing-digest` detection from `skills/_shared/hygiene-rules.md`. Present every page with its byte size, largest first — the biggest pages pay a digest back soonest.

2. **State the cost before spending it.** A rebuild reads real content. **Derive the number, don't guess it** — measurement is free (`skills/_shared/section-locator.md`, measure-before-read). Cost differs by page shape, because the two Rebuild branches in `skills/_shared/digest.md` read different sections — **sum each page under the branch it will actually take, never the project-shaped five for a batch that includes task pages**:
   - **Project-shaped pages** (has `## Overview` / `## Current Plan` / `## Session Log` by name): a rebuild reads the property block, `## Overview`, `## Current Plan`, a headline pass over `## Decisions`, and a tail slice of `## Session Log`, each bounded by that file's per-section budget.
   - **Task-shaped pages** (no fixed template): a rebuild reads the property block plus the largest one or two real sections from that page's own section map (the same derivation the Map computation performs), each capped at the per-section budget — not the project-shaped five, which routinely don't exist by name on a task page at all. Measured live, `Tasks___CRMGM-1994.md` (108,143 B) has only `## Overview` and `## Notes`; its rebuild cost is the property block plus those two sections, capped — **7,261 B**, not a sum over `## Current Plan` / `## Decisions` / `## Session Log`, none of which exist on this page.

   Size each in-scope page's actual sections with the section-map grep and `wc -c`, cap each at its budget under the correct branch, and sum across the batch. Quote the sum: *"14 pages, ~340 KB on disk — the bounded reads come to roughly 90 KB. Proceed?"* Never begin without this.

3. **Offer a scope.** Default to **project pages only** (fewer, higher value); offer "all" to include task pages, or a specific list. Let the user cut the batch down.

4. **Back up first — unconditionally.** Digest writes are two surgical Edits per page (property block, `## Digest` section), so the standard backup rule in step 4 of the main Process applies to this flow exactly as it does to a repair. The graph is usually not git-tracked; there is no undo. If the backup fails, stop.

5. **Build each digest** per the rebuild-from-source procedure in `skills/_shared/digest.md` — section reads under budget, Session Log tail-first, Map computed, 800-byte cap enforced before writing. One page at a time, so an interruption leaves a consistent graph.

6. **Report the result** — pages built, pages skipped, total bytes read — and write a journey-log entry per `skills/_shared/journey-log.md`: `backfilled N digests`.

**Never build a digest without confirmation.** It is a write, and it costs tokens; both are the user's call.

## Important Notes

- **Report before repair, backup before write, confirm before both.** A graph is the user's long-term memory; never mutate it silently.
- **A link to a missing page is not always a bug.** Users legitimately reference tickets/pages that don't exist yet. Surface these but default to leaving them unless the user says otherwise.
- **Logseq may be running.** Recommend the user close Logseq (or pause Sync) during a bulk fix to avoid mid-write sync conflicts.
- **Prevention beats cure.** When you finish, remind the user that `brain-save` now follows the compose-time invariants (`skills/_shared/logseq-format.md`), so a freshly maintained graph should stay clean.
