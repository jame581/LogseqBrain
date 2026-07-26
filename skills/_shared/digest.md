# Digest — the cheap-recall surface

Every project and task page carries a small, always-current summary that Claude reads *instead of* the page. Brief load costs one Read (~2 KB) rather than ~27 KB, and the digest's map bullet states exactly what was **not** read — which is what stops the model reasoning from a fragment as though it held the whole history.

Read this file whenever you build, refresh, rebuild, or lint a digest.

## Scope

- **In scope:** `pages/Projects___*.md` and `pages/Tasks___*.md`.
- **Out of scope:** pages with `type:: session-archive` (filenames ending `___SessionArchive.md`), and the singletons `Index.md`, `Meta.md`, `Decisions.md`.

## Surface 1 — page-top properties

Appended to the page's existing property block. Never reorder or remove the properties already there.

| Property | Meaning | Rules |
|---|---|---|
| `focus::` | what is being worked on now | one line, ≤ 120 bytes, **required** |
| `next::` | the single immediate next action | one line, ≤ 120 bytes, **required** |
| `open::` | open question or blocker | one line, ≤ 120 bytes; **omit the line entirely when there is none** — never write `open:: none` |
| `digest-updated::` | `yyyy-MM-dd` this digest was last written | **required**; the drift signal for `stale-digest` |

```
type:: project
status:: active
created:: 2026-04-15
last-updated:: 2026-07-25
focus:: Hangfire unification — phase 2 of 4
next:: CRMGM-2016 rollout to STAGE
open:: backup retention window undecided
digest-updated:: 2026-07-25
```

Property values are ordinary content and obey **every** compose invariant in `skills/_shared/logseq-format.md` — backticks for code (never `{{ }}`), escaped `#` before numbers and hex colors, namespaced `[[Tasks/…]]` and `[[Projects/…]]` links, markdown links rather than `[[file://]]`.

Two Logseq OG behaviours worth knowing, so they are not rediscovered: with `:property-pages/enabled? true` (the default) the keys `focus` / `next` / `open` become Logseq property pages — cosmetic and accepted; and unless `:property/separated-by-commas` names a key, commas inside a value are **not** parsed as page references.

## Surface 2 — the `## Digest` section

Sits immediately after the property block and before the first `## ` section, whatever it is called — `## Overview` on project pages. Task pages have no fixed template and often no `## Overview` at all, so the rule is general: right after the properties, before whatever section heading comes first in the file.

```markdown
- ## Digest
  - Product catalog integration platform: SAP / STEP PIM → SQL + Mongo → REST APIs
  - Now: unifying 5 Hangfire schedulers behind one dispatcher (phase 2 of 4)
  - Binding: 2026-04-17 DEV Mongo removed; whole-DEV decommission still undecided
  - Hazard: GLOPRICE-399 migration overlaps Price Checker hosts
  - Map: Session Log | 87 KB (47 entries) · Active Tasks | 10 KB · Current Plan | 3 KB · Decisions | 2 KB (2) · +6 smaller sections, 2 KB · Archive | [[Projects/Unicorn-Globus/SessionArchive]] · page | 107 KB
```

Each clause is `<label> | <figure>` — see "Format" below for why the ` | ` is there and not just a space.

**Slots** — 2 to 6 bullets, in this order. **Identity (slot 1) and Map are required.** Include **Now** whenever the page has any state to report — in practice almost always, since it is derivable from `## Current Plan`. Slots 3–5 as the page warrants. Never pad to hit a count: a two-bullet digest on a page with nothing to say is correct, and a hollow "Now: no updates" bullet is not.

1. **Identity** — what this project or task *is*. The most stable line; changes rarely.
2. **Now** — current state and phase.
3. **Binding** — dated decisions that still constrain the work. Prefer a *pointer* (`2026-04-17 DEV Mongo removed`) over restated reasoning; the reasoning lives in `## Decisions` and is one grep away.
4. **Hazard** — gotchas, overlaps, traps.
5. *(free)* — anything the slots above miss.
6. **Map** — computed, always last, always present, derived from the page's own section map (see below) rather than a fixed field list.

**Hard cap: 800 bytes** for the whole section, map included. Measure before writing:

```bash
awk '/^(- )?## Digest/{f=1;next} f&&/^(- )?## /{exit} f' "$p" | wc -c
```

Over cap → recompress in this order:

1. **Shrink the Map first, not the prose.** The Map's own "fitting the 800-byte cap" rule (below) reserves room for its own tail *before* accepting a single candidate, so this case is now rare — but if the prose slots alone already exceed the cap, drop the Map's above-threshold candidates smallest-first and say `+N more`.
2. If the Map alone (down to its single largest entry, the reconciling residual, the Archive pointer, and the page total — never fewer) still leaves no room, drop the free slot.
3. Still over → shorten Binding and Hazard.

**Never drop the Map wholesale** — it can shrink internally, but a digest with no Map at all is a missing digest (`missing-digest`), not a compressed one. Never write an over-cap digest — see `oversized-digest` in `skills/_shared/hygiene-rules.md`.

Task-page digests run thinner — typically Identity + Now + Map — because task pages have no fixed template.

## The Map bullet is measured, never remembered

Prose can be wrong in ways arithmetic cannot, so compute the map at write time — and compute it from the page's **actual** section map, not a fixed field list. A fixed list (the earlier `Session Log · Decisions · Implementation · Archive · page`) under-describes any page whose real structure has grown past it: measured live, `## Active Tasks` was a project page's second-largest section (10,608 B, 10% of the page) and never appeared in the map at all, so `brain-load`'s "not read" statement — which presents itself as a complete account of what was skipped — silently omitted 11% of the page. The map must describe the page it is actually attached to, not the shape of a template.

### Derivation shell

Enumerate the page's real sections (excluding `## Digest` itself, which is the map, not a mapped section), measure each, keep the ones at or above a **1 KB threshold** — below that they are noise, not signal — and sort largest first:

```bash
p="pages/Projects___<Name>.md"
threshold=1024
total=$(wc -c < "$p")
totallines=$(awk 'END{print NR}' "$p")   # NOT wc -l: Logseq writes files with no
                                        # trailing newline (all 49 pages of the reference
                                        # graph), so wc -l undercounts by one and the last
                                        # section silently loses its final line — measured
                                        # at 425 B on a real page, enough to shift a KB figure

grep -nE '^(- )?## ' "$p" | grep -v '## Digest$' > /tmp/secmap.txt
nsecs=$(wc -l < /tmp/secmap.txt)

: > /tmp/sizes.txt
i=1
while [ "$i" -le "$nsecs" ]; do
  line=$(sed -n "${i}p" /tmp/secmap.txt)
  lineno=$(echo "$line" | cut -d: -f1)
  heading=$(echo "$line" | sed -E 's/^[0-9]+:(- )?## //')
  next=$((i+1))
  if [ "$next" -le "$nsecs" ]; then
    endline=$(( $(sed -n "${next}p" /tmp/secmap.txt | cut -d: -f1) - 1 ))
  else
    endline=$totallines
  fi
  bytes=$(sed -n "$((lineno+1)),${endline}p" "$p" | wc -c)
  echo "$bytes|$heading|$lineno|$endline" >> /tmp/sizes.txt
  i=$((i+1))
done

awk -F'|' -v t="$threshold" '$1+0>=t' /tmp/sizes.txt | sort -t'|' -k1,1 -rn > /tmp/candidates.txt
awk -F'|' -v t="$threshold" '$1+0<t'  /tmp/sizes.txt > /tmp/noise.txt
noise_n=$(wc -l < /tmp/noise.txt)
noise_bytes=$(awk -F'|' '{s+=$1} END{print s+0}' /tmp/noise.txt)
```

`/tmp/candidates.txt` is now every section at or above 1 KB, largest first, as `bytes|heading|lineno|endline`. `/tmp/noise.txt` is everything that didn't clear the threshold — `noise_n` and `noise_bytes` feed the reconciling residual clause (see "Fitting" below), so the Map's figures account for the whole page, not just its above-threshold sections.

For whichever of `Session Log` and `Decisions` clear the threshold, add an entry/decision count as a parenthetical, scoped to that section's own `lineno+1`–`endline` range:

```bash
grep -cE '^[[:space:]]*- (#{2,6} +)?\[?\[?[0-9]{4}-[0-9]{2}-[0-9]{2}'
```

**The pattern must match a `### `-style dated sub-heading, not only a plain dash-bullet.** Measured live: a task page wrote every Session Log entry as `- ### 2026-05-25 — …`; the plain-dash-only form (`^[[:space:]]+- \[?\[?[0-9]{4}-…`, no optional `#{2,6}`) counted 5 where the section actually held 12 — a Map that understates by more than half, and the old honesty rule (below) only fires on a count of exactly 0, so a wrong-but-nonzero count published as if it were true. The pattern above matches either form.

**Cross-check before publishing the count — a widened pattern is not a guarantee against the next unseen entry shape.** Compute the section's own top-level child-bullet count: the bullets at the section's shallowest indentation level (its immediate children), excluding property-style lines (`^[a-z][a-z0-9-]*:: `) and italic-only stub lines (`_..._`) — the same two exclusions the entry count has always honored. If the dated-entry count comes back **lower** than this child-bullet count, treat the shortfall as a signal the pattern is still missing some entry shape on this particular page, and **omit the count** rather than publish a number already known to be a floor. A dated entry legitimately nested one level deeper than its siblings (an addendum under a same-day entry, say) makes the count *exceed* the child-bullet count — that is not a floor and is not flagged; the check only fires on undercounting. This is additive to the existing zero-only rule below, not a replacement for it.

### Fitting the 800-byte cap

The pieces appended **after** the candidate list — `+N more`, the reconciling residual, the `Archive` pointer, and the page total — are never optional once they apply, so their length must be **reserved before the first candidate is accepted**, not discovered after they've already pushed the section past the cap:

1. **Compute the fixed tail first**, independent of which candidates get kept: the `Archive` clause (if the archive page exists), the reconciling residual `+N smaller sections, X KB` (if `noise_n` ≥ 1 — see "Format" below), and the `page` clause. Measure each including its leading ` · `.
2. **Reserve worst-case room for `+N more`.** The largest N could ever be is `(candidate count − 1)` — every candidate but the single largest gets dropped. Measure ` · +<that N> more` once; this is a reservation, not necessarily what gets printed.
3. `budget_for_candidates = 800 − (prose bullets already composed) − len("Map: ") − archive_bytes − residual_bytes − page_bytes − reserved_more_bytes`.
4. Append candidates **largest first** against `budget_for_candidates`, tracking the running total exactly as before. The moment the next candidate would exceed it, stop — the remainder are the smallest, by construction of the largest-first sort.
5. Append, in order: kept candidates, `+N more` (only if any were actually dropped — using the *actual* N, always ≤ the step-2 reservation), the reconciling residual, the `Archive` pointer, the page total.

Reserving worst-case for `+N more` can leave a few bytes of slack unused when fewer candidates are dropped than the reservation assumed — that is the correct trade: a Map a few bytes under 800 is safe, a Map at 808 B is not.

Worked example, `Tasks___CRMGM-1937.md` (81,399 B, 157 B prose head, no archive page, 13 candidates clear the 1 KB threshold): reserving for the worst case (`+12 more`, 12 B), the residual clause (`+8 smaller sections, 4 KB`, 29 B with its separator) and `page | 79 KB` (16 B with its separator) leaves 581 B for candidates. Capping every label at 40 characters (§Format) shrinks the candidate clauses enough that **all 13 fit** in 529 B — no `+N more` needed. Final section: 157 (prose) + 5 (`Map: `) + 529 (13 candidates) + 29 (residual) + 16 (page) = **736 B**, under the cap, the reservation's slack simply unused because nothing had to be dropped.

Older worked example (pre-reservation, kept for the "drop smallest first" mechanic it still illustrates): forcing a real page's candidates through an artificially tight budget kept only the single largest entry and reported `+3 more` — three smaller-but-still-above-threshold sections dropped, largest-first order preserved, nothing invented.

### Format

```
  - Map: Session Log | 87 KB (47 entries) · Active Tasks | 10 KB · Current Plan | 3 KB · Decisions | 2 KB (2) · +6 smaller sections, 2 KB · Archive | [[Projects/Unicorn-Globus/SessionArchive]] · page | 107 KB
```

Each clause is `<label> | <figure>`, clauses still joined by ` · `. The ` | ` is a **reserved separator** — split on it, not on "the first space followed by a digit." A cut like the latter breaks the instant a label contains its own digits, which real task-page headings do constantly (`2026-04-23 — Step 2 isolated, real root cause found`, `PROD 2.6 — EXECUTED 2026-06-01 …`): the old approach cut mid-label and produced a truncated, sometimes-colliding key. Splitting on the reserved token instead never depends on what characters a label happens to contain.

- **Label** — the section heading verbatim, **capped at 40 characters**. Longer than that: cut to the first 40 characters and append `…`. The truncated string doubles as the *diff key* — `stale-map` re-truncates the real heading the same way (first 40 characters) before comparing labels, so cutting for display never loses the ability to relocate the section, only its display length.
- **Figure** — `N KB` or `N B` (truncation rule under "Rules" below); `Session Log` and `Decisions` carry their count immediately after the figure — `N KB (M entries)` / `N KB (M)`.
- **`Archive`** — `Archive | [[Projects/<Name>/SessionArchive]]` (a pointer, not a figure — recognized by its value starting `[[`, never by clause position).
- **`page`** — `page | N KB`, always last.
- **The reconciling residual** — `+N smaller sections, X KB` (or `X B` under 1 KB), present whenever `noise_n` ≥ 1 (at least one real section fell under the 1 KB threshold). Not a section name: it's recognized by its `+N smaller sections` prefix and never looked up as a heading. This is what lets the Map's figures — candidates, `+N more`, residual, `page` — account for the *whole* page, not just the sections that individually cleared the threshold: measured live on `Tasks___CRMGM-1937.md`, 8 sections totaling 4,121 B cleared no threshold and, before this clause existed, appeared in the Map nowhere at all.

**Duplicate labels are a finding, not a collision to key through.** Two headings can truncate to the same 40 characters — measured live, two same-day task-page entries both start `2026-04-23 — Step 2…` and differ only after character 20, so a too-short cap would collide them. Before finalizing the Map, check whether any two included labels are identical after truncation; if so, widen *that pair's* truncation only, as far as needed to disambiguate (up to the full heading length), rather than let either one silently key to the wrong section. `skills/_shared/hygiene-rules.md`'s `stale-map` performs the same check on whatever a Map actually claims: two clauses parsing to the same label is reported as its own finding, and neither of that pair is diffed — the key is ambiguous, not wrong, and guessing which is which would be worse than saying so.

Worked example, measured live on `Projects___Unicorn-Globus.md` (109,786 B total): the derivation shell found 10 real sections, kept the 4 at or above 1 KB (`Session Log` 89,171 B, `Active Tasks` 10,590 B, `Current Plan` 3,153 B, `Decisions` 2,622 B), and summarized the other 6 as noise (`Overview` 415 B, `Tech Stack` 322 B, `Key Projects` 555 B, `Architecture` 526 B, `Conventions` 426 B, `Implementation` 361 B — 2,605 B total) in a single reconciling clause, `+6 smaller sections, 2 KB`, rather than omitting them. The full line — four candidates, the residual, the Archive pointer, the page total — runs comfortably inside the 800 B cap alongside four prose slots.

### Rules

- **Byte figures are authoritative and always emitted** for every section that clears the threshold. Above 1 KB, a claim of `N KB` asserts the section measures **somewhere in `[N·1024, N·1024 + 1023]` bytes** — truncate to that floor, never round to nearest (see "The `page` figure" below for why the direction matters, and `stale-map` in `skills/_shared/hygiene-rules.md` for why the tolerance this implies is one-sided, not a symmetric ± band). Below 1 KB use exact bytes.
- **The 1 KB threshold is a hard floor for inclusion**, independent of the 800 B cap — a section under 1 KB is omitted from the map even when there is room to spare. It isn't signal. A section that shrinks below 1 KB after previously clearing it (rotation, a doctor repair) must be **dropped** from the Map on the next Remap/Refresh, not left in at a stale figure — `stale-map` flags any claimed section it re-measures at under 1 KB, on the theory that this rule was skipped.
- **Entry counts (`Session Log`) and decision counts (`Decisions`) are best-effort**, keyed off the dated-headline shape — `grep -cE '^[[:space:]]*- (#{2,6} +)?\[?\[?[0-9]{4}-[0-9]{2}-[0-9]{2}'` — which matches a `### `-style dated sub-heading as well as a plain dash-bullet (see "Derivation shell" above for why the `#{2,6}` alternative is required, not cosmetic). Mirrors the Decision Entry Template (`{{date}}: {{decision_title}}`) so that free-form children (a `**Consequences:**` sub-list, an undated aside) don't get counted as their own entries. As before: an **undated** entry is not counted, so when a section has content but the dated-headline count comes back 0, omit the count rather than write `0 entries`/`(0)`. **New:** a *nonzero* count that comes back lower than the section's own top-level child-bullet count (see the cross-check above) is also omitted — a wrong-but-nonzero count is not more honest than a zero one.
- **Every figure is scoped to its own section** — the same `lineno`–`endline` boundaries the derivation shell computes, never a blind whole-file grep. An unscoped count over the whole page would, for instance, count dated `## Decisions` bullets as Session Log entries.
- **Absent sections are omitted**, never reported as zero.
- **Labels are capped at 40 characters**, truncated with a trailing `…` when the real heading runs longer, and joined to their figure with the reserved ` | ` separator — see "Format" above. Never key two different labels to the same truncated string; widen the cap for a colliding pair before falling back to it.
- **Include the `Archive` pointer only when** `pages/Projects___<Name>___SessionArchive.md` exists — unchanged, and never subject to the drop-for-space rule.
- **Include the reconciling residual (`+N smaller sections, X KB`) whenever `noise_n` ≥ 1** — never subject to the drop-for-space rule, reserved for up front (see "Fitting" above).
- **The page total is always emitted** and never subject to the drop-for-space rule — it's the one figure that lets `brain-load` say "this is everything, and here's how much of it I read."
- **Placeholder stubs** (`_Session entries are added by brain-save._` and friends) still denote an empty section — a section holding only its stub measures near-zero and is naturally filtered out by the 1 KB threshold, no special-casing needed.

### The `page` figure needs a second pass — the other figures don't

Writing the digest is itself a write to the page: the property-block Edit and the `## Digest` Edit both change the file's own byte count. Every other figure in the map (`Session Log`, `Active Tasks`, whatever cleared the threshold) measures a section the digest edit does not touch, so computing it once, before writing, stays correct. `page` is different — it measures the whole file, including the very bullet being edited to state it — so a `page` figure computed before the write and never revisited is stale the moment the write lands.

Measured live: a Map computed *before* a first-digest write claimed `page 106 KB`; the digest edits added the usual few hundred bytes; the file measured 109,786 B = 107 KB immediately afterward. That crossed a KB boundary, and the 1,242 B drift exceeded `stale-map`'s 1,024 B KB-tier tolerance — a correctly-computed Map, false-flagged as stale by an artifact of write order. Widening the tolerance again is not the fix (it has already been widened twice for this one figure); the fix is to close the gap the same way `brain-init` already closes it for `{{page_size}}` on a brand-new page — measure again *after* the write:

1. Compute the map (above) using the page's byte count **before** this save's edits — this is what makes `sl`/`dec`/etc. cheap: one measurement, taken alongside everything else.
2. Write the property-block edit and the `## Digest` edit.
3. Re-measure the page: `wc -c < "$p"`.
4. If the new total's rounded figure differs from the `page` figure just written, Edit that one bullet again to correct it. On a page above 1 KB this is a single `wc -c` plus, at most, a one-character digit swap (`106 KB` → `107 KB`) — cheap enough to do unconditionally rather than only when a boundary crossing is suspected.

This is a numbered step in `skills/brain-save/SKILL.md` step 9, not a footnote — every flow that writes a digest (Refresh, Rebuild, Remap) inherits it from here.

## Building a digest — three paths

### Refresh (cheap, every save)

Rewrite the properties and bullets from the session knowledge that produced the Session Log entry and Current Plan, then recompute the Map. Unconditional — see `brain-save` step 9. Cost: ~1 read + 1 edit.

Unconditional by design: v0.9.0 recorded the lesson for the `Index.md` one-liner — *rot comes precisely from "only when it changed" judgment calls.*

### Remap (cheapest, byte-moving writes only)

Recompute **only** the Map bullet. Leave every prose slot (Identity, Now, Binding, Hazard, the free slot) exactly as it was — and leave `digest-updated::` alone too. A Remap writes the *Map*, not the digest: bumping the date would silence `stale-digest` for another 30 days on prose nobody touched. The two signals stay orthogonal — `stale-map` guards the Map arithmetically, `stale-digest` guards the prose by date. This is the correct response to a write that moved or changed the page's *bytes* without changing what the page *means* — the Session Log got smaller (rotation) or a format violation got fixed (a `brain-doctor` repair), but the project itself didn't change. Cost: the same one Bash call as the Map computation above, plus one Edit touching only the Map bullet.

Neither of the other two paths fits a byte-moving write. Refresh rewrites the prose slots **from the session knowledge that produced this save** — rotation and a doctor repair have no such session, so calling either of them "Refresh" would mean rewriting prose from nothing (silently blanking it) or silently reusing stale prose under a freshly-stamped `digest-updated::` (looking current while saying nothing new) — which is exactly why a Remap leaves that date alone. Rebuild re-reads the page section by section, which is exactly the cost a write that only moved bytes doesn't need to pay.

**Triggers:** `skills/brain-save/references/rotation.md` step 6, after a confirmed rotation (on the project page and on the archive page too, if it carries a digest); `brain-doctor`'s repair verify step, for every page whose bytes changed during a fix.

### Rebuild from source (expensive, corrective)

Refresh only ever knows the current session, so across dozens of sessions a digest slowly sheds facts that are old but still true. Rebuild re-derives the digest **from the page**.

**Triggers:** the page has no `digest-updated::` and is being loaded or saved (lazy backfill); `digest-updated::` is more than 30 days behind `last-updated::` (**suggest** — never spend silently); brain-doctor's guided backfill; explicit "rebuild digest for X".

**Procedure:**

1. Read the property block and `## Overview` → Identity.
2. Read `## Current Plan` → Now, and `next::`.
3. Read `## Decisions` — headline lines only → Binding.
4. Read `## Session Log` **tail-first**: recent entries carry more signal per byte. Stop as soon as the slots are filled or the byte budget in `skills/_shared/section-locator.md` is spent.
5. Where `pages/Projects___<Name>___SessionArchive.md` exists, read **its digest**, never its contents.
6. Compute the Map, check the 800-byte cap, write.

**Never read the whole file in a single Read during a rebuild** — that is the cost this feature exists to avoid.
