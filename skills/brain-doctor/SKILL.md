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

Scan the whole graph for the format mistakes that silently corrupt a Logseq graph. Report them and, on confirmation and after a backup, repair them. This is a maintenance tool: run it on demand, not in the save/load cycle. Detection runs through the helper (`skills/_shared/run-brain.md`). The catalog of meaning, tiers and remediation is `skills/_shared/hygiene-rules.md`.

## Prerequisites

Run `brain info` once, and use its `graph:` path for the backup and for every Edit this skill makes. If it exits 2, follow `skills/_shared/path-resolution.md`, then pass `--graph` to every call.

## Modes

- **Report** (default: "lint brain" / "check brain health" / "why are there empty pages"): detect and summarize, change nothing.
- **Fix** ("fix brain" / "clean up brain" / "yes, fix them" after a report): repair after a backup, with confirmation.

If the trigger is ambiguous, run Report first and offer to fix.

## Process

1. **Scan in one call: `brain lint --all`.** It prints every mechanical rule, plus the digest rules for every digest-bearing page, as `file:line rule tier detail`, followed by a `summary:` line. Then run the three judgment rules the helper does not: `description-link` (from the phantom-target procedure under `broken-link`), `duplicate-entry` and `structural-integrity`, per the catalog.

2. **Report**, grouped by the catalog's `auto-fixable` field:
   - **Auto-fixable:** `code-in-braces`, `bare-hash-tag`, `unnamespaced-link`, `file-link`, `relative-link`, `malformed-property` (page-top only), and `stale-map` / `map-label`. The digest ones are fixed with `brain digest <page> --apply`.
   - **Needs your call:** `description-link`, `broken-link`, `new-property-key`, `duplicate-entry`, `structural-integrity`, `jira-markup`, `missing-digest`, `stale-digest`, `oversized-digest`.

   The headline total counts **every** bucket. Example:

   ```
   Brain health: 16 issues across 8 pages
   Auto-fixable (5):   3 bare #tags (incl. C#-parity), 1 {{code}}, 1 stale Map
   Needs your call (7): 4 links to missing task pages, 2 one-off property keys, 1 unfenced Jira draft
   Digests (4):        4 pages with no digest — say "backfill digests"
   ```

   **Empty pages that lint no longer explains:** Logseq never deletes a page once it has parsed one. Pages created by text that has since been fixed survive until the graph is **re-indexed** in Logseq (All graphs → Re-index). A clean `brain lint` plus leftover empty pages means "re-index", not "fix more". If the graph is clean, say so, run `brain activity "ran brain-doctor (clean)"`, and stop.

3. **Confirm before any write.** Ask which classes to fix if the user hasn't said.

4. **Back up first.** The graph is usually not git-tracked, so there is no undo. Copy `pages/`, `journals/` and `logseq/` to a timestamped folder (e.g. `<graph>/.brain-doctor-backup-<yyyy-MM-dd-HHmm>/`, or the host scratchpad) and say where. If the backup fails, stop.

5. **Repair.**
   - **Mechanical classes:** Edit each hit per the catalog's remediation. For high-volume classes a single scripted pass is acceptable (this is one-time maintenance, and a backup exists), but it must mask fenced blocks and inline code exactly as the catalog says.
   - **`stale-map` / `map-label`:** `brain digest <page> --apply` per page.
   - **Needs-your-call findings:** walk them with the user and apply only what they approve. Never auto-write `broken-link`, `duplicate-entry` or `structural-integrity` changes.

6. **Verify.**
   - `brain lint <every file you changed>`: expect zero for the fixed classes.
   - Per-file backtick parity (the catalog's "After repair — verify").
   - Then `brain digest <page> --apply` on every digest-bearing page whose bytes changed. This is a Remap: `digest-updated::` and the prose stay untouched.

7. **`brain activity "ran brain-doctor · fixed <N> issues"`** and report the result.

## Guided digest backfill

Triggered by "backfill digests" or accepted from a `missing-digest` report. The shape is: report, cost, one confirmation, then work.

1. **Report what is missing:** the `missing-digest` rows from `brain lint --all`. These are pages with no `## Digest`, and pages whose Digest has no Map line (e.g. `Tasks/CRMGM-2037`). List each with its size from `brain sections`, largest first; the biggest pages pay back a digest soonest.
2. **State the cost before spending it.** For each page, `brain sections <page>` gives the sections its Rebuild branch will read (`skills/_shared/digest.md`). Project-shaped pages read Overview, Current Plan, the Decisions headlines and the Session Log tail. Task-shaped pages read their largest one or two sections. Cap each at 8 KB and sum. Quote the sum: *"14 pages, ~340 KB on disk — the bounded reads come to roughly 90 KB. Proceed?"*
3. **Offer a scope:** project pages by default; "all" includes task pages.
4. **Back up first**, unconditionally.
5. **Build each digest** per the Rebuild procedure in `skills/_shared/digest.md`: bounded reads, then prose Edits, then `brain digest <page> --apply`. Work one page at a time, so an interruption leaves a consistent graph.
6. **Report** pages built, skipped and bytes read. Then `brain activity "backfilled N digests"`.

**Never build a digest without confirmation.** It is a write, and it costs tokens.

## Important Notes

- **Report before repair, backup before write, confirm before both.**
- **A link to a missing page is not always a bug.** Tickets that don't have a page yet are legitimate forward references. Surface them, but leave them unless the user says otherwise.
- **Logseq may be running.** Recommend closing it (or pausing Sync) during a bulk fix.
