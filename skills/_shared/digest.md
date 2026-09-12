# Digest — the cheap-recall surface

Every project and task page carries a small, always-current summary that Claude reads *instead of* the page. A brief load is one helper call, `brain digest <page>`: it prints the property block and the whole `## Digest` section, then stops — on the maintainer's largest project page, `Projects___Unicorn-Globus.md` (109,760 B), that call reads about 1.4 KB rather than the whole page. The Map bullet it prints states exactly what was **not** read, which is what stops the model reasoning from a fragment as though it held the whole history.

Read this file whenever you build, refresh, rebuild, or lint a digest.

## Scope

- **In scope:** `pages/Projects___*.md` **with `type:: project`**, and `pages/Tasks___*.md`.
- **Out of scope:** pages with `type:: session-archive` (filenames ending `___SessionArchive.md`); the singletons `Index.md`, `Meta.md`, `Decisions.md`; and — same reasoning as the archive exclusion — auxiliary pages that merely live under the `Projects___` namespace without being a project page themselves, e.g. `type:: task-index` (a project's task inventory, like `Projects___Unicorn-Globus___Tasks.md`) or `type:: project-note` (a standalone note, like `Projects___Unicorn-Globus___ClaudeCodeAutomation.md`). These match the `pages/Projects___*.md` glob but are not projects, so every rule that iterates that glob (`missing-digest`, `stale-digest`, `stale-map`, `oversized-digest`, and `brain-status`'s census) must check `type:: project` before counting a hit — a filename match alone is not enough, exactly as `___SessionArchive.md` alone is not enough without the `type::` check.

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
  - Map: Session Log | 87 KB (47 entries) · Active Tasks | 10 KB · Current Plan | 3 KB · Decisions | 2 KB (2) · +6 smaller sections, 2 KB · page | 107 KB
```

Each clause is `<label> | <figure>` — see "Format" below for why the ` | ` is there and not just a space.

**Slots** — 2 to 6 bullets, in this order. **Identity (slot 1) and Map are required.** Include **Now** whenever the page has any state to report — in practice almost always, since it is derivable from `## Current Plan`. Slots 3–5 as the page warrants. Never pad to hit a count: a two-bullet digest on a page with nothing to say is correct, and a hollow "Now: no updates" bullet is not.

1. **Identity** — what this project or task *is*. The most stable line; changes rarely.
2. **Now** — current state and phase.
3. **Binding** — dated decisions that still constrain the work. Prefer a *pointer* (`2026-04-17 DEV Mongo removed`) over restated reasoning; the reasoning lives in `## Decisions` and is one grep away.
4. **Hazard** — gotchas, overlaps, traps.
5. *(free)* — anything the slots above miss.
6. **Map** — computed, always last, always present, derived from the page's own section map (see below) rather than a fixed field list.

**Hard cap: 800 bytes** for the whole section, map included. `brain digest <page> --apply` fits the Map itself, dropping its smallest candidates into `+N more` when needed. If the prose alone leaves too little room, it reports `digest prose over cap by N B`: shorten the free slot, then Binding and Hazard, and rerun. Never drop or hand-edit the Map.

Task-page digests run thinner — typically Identity + Now + Map — because task pages have no fixed template.

## The Map bullet is computed by the helper, never written by hand

`brain digest <page> --apply` derives the Map from the page's actual sections, and replaces only the Map line (or inserts it as the Digest's last bullet). **Never hand-edit the Map line, and never compute a figure yourself.** Hand arithmetic is how Maps went wrong: rounded figures, paraphrased labels and over-cap digests were all measured on the live graph on 2026-09-11 (`docs/superpowers/specs/2026-09-11-v0.11.0-design.md`).

What the helper implements, so you can *read* a Map:

- **Candidates:** every `## ` section except `## Digest`, measured as the bytes after its heading up to the next heading. Sections ≥ 1 KiB are candidates, largest first. The rest are summarized in one `+N smaller sections, X` clause, so the Map accounts for the whole page.
- **Figures** are KiB, **truncated**: `N KB` asserts N·1024 … N·1024+1023 bytes. Below 1 KiB, exact bytes. `Session Log` and `Decisions` carry their dated-entry count (`(N entries)` / `(N)`) only when it passes a cross-check against the section's top-level bullets; otherwise the count is omitted.
- **Labels** are the heading, or its first 40 bytes (cut at a UTF-8 character boundary) plus `…`. Two labels that would collide are widened until they differ.
- **Order:** clauses are `label | figure`, joined by ` · `. Kept candidates come first, then `+N more` (when the 800 B cap forced drops), the smaller-sections residual, `Archive | [[Projects/<Name>/SessionArchive]]` (when that page exists), and finally `page | <total>`. The page total is computed for the file as it will be after the write.
- Example: `- Map: Session Log | 87 KB (47 entries) · Active Tasks | 10 KB · Current Plan | 3 KB · Decisions | 2 KB (2) · +6 smaller sections, 2 KB · page | 107 KB`

`brain digest <page>` (without `--apply`) reports `map: ok`, `map: stale · <clause> → <measured>`, or `map: missing`. The `stale-map` and `map-label` lint rules use the same computation.

## Building a digest — three paths

### Refresh (cheap, every save)

Rewrite the properties and bullets from the session knowledge that produced the Session Log entry and Current Plan, then run `brain digest <page> --apply`. Unconditional — see `brain-save` step 8. Cost: ~1 read + 1 edit.

Unconditional by design: v0.9.0 recorded the lesson for the `Index.md` one-liner — *rot comes precisely from "only when it changed" judgment calls.*

### Remap (cheapest, byte-moving writes only)

Recompute **only** the Map bullet. Leave every prose slot (Identity, Now, Binding, Hazard, the free slot) exactly as it was — and leave `digest-updated::` alone too. A Remap writes the *Map*, not the digest: bumping the date would silence `stale-digest` for another 30 days on prose nobody touched. The two signals stay orthogonal — `stale-map` guards the Map arithmetically, `stale-digest` guards the prose by date. This is the correct response to a write that moved or changed the page's *bytes* without changing what the page *means* — the Session Log got smaller (rotation) or a format violation got fixed (a `brain-doctor` repair), but the project itself didn't change. Cost: one call — `brain digest <page> --apply`, which touches only the Map line.

Neither of the other two paths fits a byte-moving write. Refresh rewrites the prose slots **from the session knowledge that produced this save** — rotation and a doctor repair have no such session, so calling either of them "Refresh" would mean rewriting prose from nothing (silently blanking it) or silently reusing stale prose under a freshly-stamped `digest-updated::` (looking current while saying nothing new) — which is exactly why a Remap leaves that date alone. Rebuild re-reads the page section by section, which is exactly the cost a write that only moved bytes doesn't need to pay.

**Triggers:** `skills/brain-save/references/rotation.md` step 6, after a confirmed rotation (on the project page and on the archive page too, if it carries a digest); `brain-doctor`'s repair verify step, for every page whose bytes changed during a fix.

### Rebuild from source (expensive, corrective)

Refresh only ever knows the current session, so across dozens of sessions a digest slowly sheds facts that are old but still true. Rebuild re-derives the digest **from the page**.

**Triggers:** the page has no `digest-updated::` and is being loaded or saved (lazy backfill); `digest-updated::` is more than 30 days behind `last-updated::` (**suggest** — never spend silently); brain-doctor's guided backfill; explicit "rebuild digest for X".

**Procedure — project-shaped pages** (has `## Overview`, `## Current Plan`, and `## Session Log` by name — the standard project template):

1. Read the property block and `## Overview` → Identity.
2. Read `## Current Plan` → Now, and `next::`.
3. Read `## Decisions` — headline lines only → Binding.
4. `brain tail <page> "Session Log" --entries 3 --max 4096` — recent entries carry more signal per byte. Stop once the slots are filled.
5. Where `pages/Projects___<Name>___SessionArchive.md` exists, read **its digest**, never its contents.
6. Write the properties and prose slots with Edit, then `brain digest <page> --apply`.

**Procedure — task-shaped pages (no fixed template):** task pages routinely have none of `## Overview` / `## Current Plan` / `## Decisions` / `## Session Log` by that name — measured live, `Tasks___CRMGM-1994.md` (108,143 B) has only `## Overview` (1,335 B) and `## Notes` (106,526 B — 98% of the page). The five project-shaped steps above have nowhere to land on a page like this: none of them names `## Notes`, so a rebuild that only knew those five headings would read almost nothing of a page that is almost nothing *but* that one section. Branch instead:

1. Read the property block (unchanged — generic regardless of page shape).
2. **`brain sections <page>`** — every real section, measured, in one call.
3. **Read the largest one or two of those candidates**, each capped at the per-section budget (`skills/_shared/section-locator.md`, ≤ 8 KB per section):
   - At or under the cap → read it whole.
   - Over the cap → `brain tail <page> "<section>" --max 8192`, which reads the newest content first.
4. **Derive Identity from the smallest/most-stable candidate** (often literally called `## Overview` even without the rest of the project template) and **Now from the most recent dated content** the tail read surfaced in the largest candidate.
5. **Skip Binding/Hazard/the free slot** when nothing in the page's real sections supports them — task-page digests already run thinner by design (typically Identity + Now + Map; see "Slots" above).
6. Where `pages/Tasks___<ID>___SessionArchive.md` exists, read its digest, never its contents (unchanged).
7. Write the prose with Edit, then `brain digest <page> --apply`.

Worked example, `Tasks___CRMGM-1994.md` (108,143 B — the spec's own §9.10 acceptance page): `brain sections` finds exactly two real sections, `## Overview` (1,335 B) and `## Notes` (106,526 B). Both clear the 1 KB threshold. Overview is under the 8 KB per-section cap, so it's read whole for Identity (256 B property block + 1,335 B). Notes is nowhere near the cap — its last 3 dated entries (the tail recipe, scoped to the section) read **5,670 B**, comfortably inside the 8 KB per-section cap, and supply Now. Total read: 256 + 1,335 + 5,670 = **7,261 B**, a two-slot digest (Identity + Now + Map) built without ever reading the 106.5 KB `## Notes` whole.

**Never read the whole file in a single Read during a rebuild** — that is the cost this feature exists to avoid, on a task page most of all, since a task page's one oversized section is usually most of the file.
