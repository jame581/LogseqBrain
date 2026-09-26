# Digest Map — derivation reference (maintainers)

Not shipped: the `.plugin` archive packages only `skills/`, `.claude-plugin/` and `README.md`. No skill reads this file. The helper implements it (`skills/_shared/lib/map.awk`, `core.awk`), and the golden cases `tests/cases/digest-*` and `apply-*` pin it. The shipped contract a skill needs (scope, the two surfaces, the slots, and the Refresh, Remap and Rebuild paths) stays in `skills/_shared/digest.md`. Moved here in v0.12.0 (`docs/superpowers/specs/2026-09-25-v0.12.0-design.md` §3.2).

## How the Map is derived

What the helper implements:

- **Candidates:** every `## ` section except `## Digest`, measured as the bytes after its heading up to the next heading. Sections ≥ 1 KiB are candidates, largest first. The rest are summarized in one `+N smaller sections, X` clause, so the Map accounts for the whole page.
- **Figures** are KiB, **truncated**: `N KB` asserts N·1024 … N·1024+1023 bytes. Below 1 KiB, exact bytes. `Session Log` and `Decisions` carry their dated-entry count (`(N entries)` / `(N)`) only when it passes a cross-check against the section's top-level bullets; otherwise the count is omitted.
- **Labels** are the heading, or its first 40 bytes (cut at a UTF-8 character boundary) plus `…`. Two labels that would collide are widened until they differ.
- **Order:** clauses are `label | figure`, joined by ` · `. Kept candidates come first, then `+N more` (when the 800 B cap forced drops), the smaller-sections residual, `Archive | [[Projects/<Name>/SessionArchive]]` (when that page exists), and finally `page | <total>`. The page total is computed for the file as it will be after the write.
- Example: `- Map: Session Log | 87 KB (47 entries) · Active Tasks | 10 KB · Current Plan | 3 KB · Decisions | 2 KB (2) · +6 smaller sections, 2 KB · page | 107 KB`

Cap fitting (the 800 B `## Digest` cap): the trailing clauses (the residual, `Archive`, `page`) and the worst-case `+N more` clause are reserved first. Candidates are then kept largest-first until the next one does not fit, and the rest are counted in `+N more`. At least the single largest candidate is always kept. If the prose alone leaves no room, `--apply` reports `digest prose over cap by N B` rather than shrinking the Map further.

The page figure is computed for the file as it will be after the write. Near a 1 KiB boundary this can fail to converge, because writing the figure changes the total: `nonconvergent-map`, and `--apply` refuses to write.

## Logseq OG behaviours around the digest properties

Two Logseq OG behaviours worth knowing, so they are not rediscovered: with `:property-pages/enabled? true` (the default) the keys `focus` / `next` / `open` become Logseq property pages — cosmetic and accepted; and unless `:property/separated-by-commas` names a key, commas inside a value are **not** parsed as page references.

## Why task pages need their own Rebuild branch

**Procedure — task-shaped pages (no fixed template):** task pages routinely have none of `## Overview` / `## Current Plan` / `## Decisions` / `## Session Log` by that name — measured live, `Tasks___CRMGM-1994.md` (108,143 B) has only `## Overview` (1,335 B) and `## Notes` (106,526 B — 98% of the page). The five project-shaped steps above have nowhere to land on a page like this: none of them names `## Notes`, so a rebuild that only knew those five headings would read almost nothing of a page that is almost nothing *but* that one section.

Worked example, `Tasks___CRMGM-1994.md` (108,143 B — the spec's own §9.10 acceptance page): `brain sections` finds exactly two real sections, `## Overview` (1,335 B) and `## Notes` (106,526 B). Both clear the 1 KB threshold. Overview is under the 8 KB per-section cap, so it's read whole for Identity (256 B property block + 1,335 B). Notes is nowhere near the cap — its last 3 dated entries (the tail recipe, scoped to the section) read **5,670 B**, comfortably inside the 8 KB per-section cap, and supply Now. Total read: 256 + 1,335 + 5,670 = **7,261 B**, a two-slot digest (Identity + Now + Map) built without ever reading the 106.5 KB `## Notes` whole.
