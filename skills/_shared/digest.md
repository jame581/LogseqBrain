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

Sits immediately after the property block, **before** `## Overview`.

```markdown
- ## Digest
  - Product catalog integration platform: SAP / STEP PIM → SQL + Mongo → REST APIs
  - Now: unifying 5 Hangfire schedulers behind one dispatcher (phase 2 of 4)
  - Binding: 2026-04-17 DEV Mongo removed; whole-DEV decommission still undecided
  - Hazard: GLOPRICE-399 migration overlaps Price Checker hosts
  - Map: Session Log 89 KB (49 entries) · Decisions 12 · Implementation 4 KB · Archive [[Projects/Unicorn-Globus/SessionArchive]] · page 109 KB
```

**Slots** — 2 to 6 bullets, in this order. **Identity (slot 1) and Map are required.** Include **Now** whenever the page has any state to report — in practice almost always, since it is derivable from `## Current Plan`. Slots 3–5 as the page warrants. Never pad to hit a count: a two-bullet digest on a page with nothing to say is correct, and a hollow "Now: no updates" bullet is not.

1. **Identity** — what this project or task *is*. The most stable line; changes rarely.
2. **Now** — current state and phase.
3. **Binding** — dated decisions that still constrain the work. Prefer a *pointer* (`2026-04-17 DEV Mongo removed`) over restated reasoning; the reasoning lives in `## Decisions` and is one grep away.
4. **Hazard** — gotchas, overlaps, traps.
5. *(free)* — anything the slots above miss.
6. **Map** — computed, always last, always present.

**Hard cap: 800 bytes** for the whole section, map included. Measure before writing:

```bash
awk '/^(- )?## Digest/{f=1;next} f&&/^(- )?## /{exit} f' "$p" | wc -c
```

Over cap → recompress: drop the free slot first, then shorten Binding and Hazard. **Never drop the Map.** Never write an over-cap digest — see `oversized-digest` in `skills/_shared/hygiene-rules.md`.

Task-page digests run thinner — typically Identity + Now + Map — because task pages have no fixed template.

## The Map bullet is measured, never remembered

Prose can be wrong in ways arithmetic cannot, so compute the map at write time. One Bash call:

```bash
p="pages/Projects___<Name>.md"
total=$(wc -c < "$p")
sl=$(awk '/^(- )?## Session Log/{f=1;next} f&&/^(- )?## /{exit} f' "$p" | wc -c)
dec=$(awk '/^(- )?## Decisions/{f=1;next} f&&/^(- )?## /{exit} f' "$p" \
      | grep -cE '^[[:space:]]+- \[?\[?[0-9]{4}-[0-9]{2}-[0-9]{2}')
impl=$(awk '/^(- )?## Implementation/{f=1;next} f&&/^(- )?## /{exit} f' "$p" | wc -c)
ent=$(awk '/^(- )?## Session Log/{f=1;next} f&&/^(- )?## /{exit} f' "$p" \
      | grep -cE '^[[:space:]]+- \[?\[?[0-9]{4}-[0-9]{2}-[0-9]{2}')
```

Format:

```
  - Map: Session Log 89 KB (49 entries) · Decisions 12 · Implementation 4 KB · Archive [[Projects/<Name>/SessionArchive]] · page 109 KB
```

Rules:

- **Byte figures are authoritative and always emitted.** Round to whole KB above 1 KB; below that use bytes.
- **Entry counts are best-effort.** Session-entry bullet formatting varies across real graphs. When `ent` is 0 but the Session Log has content, emit the bytes and **omit the count entirely** — `0 entries` would be a lie, and the map's whole job is to be trustworthy.
- **Every figure is scoped to its own section.** `sl`, `ent`, `dec`, and `impl` all bound their `awk` at the next `## ` heading. An unscoped `ent` grep silently counts dated `## Decisions` bullets as sessions — the Binding slot recommends dated decision lines, so this is the normal case, not an edge case. Scope first, count second.
- **`dec` counts keyed off the dated headline**, mirroring the Decision Entry Template (`{{date}}: {{decision_title}}`) — it counts lines matching a `yyyy-MM-dd`-prefixed bullet, not lines in general. That is what keeps free-form children (a `**Consequences:**` sub-list, extra prose) out of the count without needing to enumerate every property key a decision might carry: a page with 2 decisions reports `2`, not the 8 bullets — headline, properties, and any free-form children combined — they occupy. The trade-off is the same one `ent` already makes: an **undated** decision entry will not be counted. `dec` is therefore best-effort like `ent`, and the same rule applies — when the Decisions section has content but the dated-headline count comes back 0, omit the count rather than report `dec: 0`, which would be a lie about a non-empty section.
- **Absent sections are omitted**, never reported as zero.
- Include the `Archive` pointer only when `pages/Projects___<Name>___SessionArchive.md` exists.
- Placeholder stubs (`_Session entries are added by brain-save._` and friends) denote an empty section — a section holding only its stub counts as **0** and is omitted.

## Building a digest — two paths

### Refresh (cheap, every save)

Rewrite the properties and bullets from the session knowledge that produced the Session Log entry and Current Plan, then recompute the Map. Unconditional — see `brain-save` step 9. Cost: ~1 read + 1 edit.

Unconditional by design: v0.9.0 recorded the lesson for the `Index.md` one-liner — *rot comes precisely from "only when it changed" judgment calls.*

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
