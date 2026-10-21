# Digest — the cheap-recall surface

Every project and task page carries a small, always-current summary that Claude reads *instead of* the page. A load reads the property block and the whole `## Digest` (about 1.4 KB even on a 107 KB page) and stops. The Map bullet states exactly what was **not** read, so the model never reasons from a fragment as though it held the whole history.

Read this file whenever you build, refresh, rebuild, or lint a digest.

## Scope

- **In scope:** `pages/Projects___*.md` **with `type:: project`**, and `pages/Tasks___*.md`.
- **Out of scope:** session archives (`type:: session-archive`, filenames ending `___SessionArchive.md`); the singletons `Index.md`, `Meta.md`, `Decisions.md`; and auxiliary pages under the `Projects___` namespace that are not projects (`type:: task-index`, `type:: project-note`). A filename match alone is never enough: every digest rule and `brain-status`'s census check `type:: project`.

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

`brain digest <page> --apply` derives the Map from the page's actual sections, and replaces only the Map line (or inserts it as the Digest's last bullet). **Never hand-edit the Map line, and never compute a figure yourself.** Hand arithmetic produced rounded figures, paraphrased labels and over-cap digests.

Reading a Map: each clause is `label | figure`, joined by ` · `. Figures are KiB **truncated** (`3 KB` means 3,072–4,095 bytes), exact bytes below 1 KiB. `Session Log` and `Decisions` may carry a dated-entry count. `+N smaller sections, X` sums every section under 1 KiB, `+N more` counts candidates the 800 B cap dropped, and `page | …` is the whole file. So the Map accounts for every byte of the page. The full derivation lives in `docs/reference/digest-map.md` in the plugin's repository; skills never compute it.

`brain digest <page>` (without `--apply`) reports `map: ok`, `map: stale · <clause> → <measured>`, or `map: missing`. The `stale-map` and `map-label` lint rules use the same computation.

## Building a digest — three paths

### Refresh (cheap, every save)

Rewrite the properties and bullets from the session knowledge that produced the Session Log entry and Current Plan, in one Edit; `brain save-finish` then writes the Map. Unconditional — see `brain-save` step 5. Cost: 1 edit.

Unconditional by design: rot comes from "only when it changed" judgment calls.

### Remap (cheapest, byte-moving writes only)

For a write that changed the page's *bytes* but not what it *means*: a rotation, or a `brain-doctor` repair. Recompute **only** the Map, with `brain digest <page> --apply`, one call. Leave every prose slot **and `digest-updated::`** as they were: bumping the date would silence `stale-digest` for 30 days on prose nobody touched. `stale-map` guards the Map, `stale-digest` guards the prose.

Refresh would rewrite prose from no session knowledge, and Rebuild would pay to re-read a page whose meaning did not change, so a byte-moving write is always a Remap.

**Triggers:** `skills/brain-save/references/rotation.md` step 6, after a confirmed rotation (on the project page; archive pages carry no digest, see Scope); `brain-doctor`'s repair verify step, for every page whose bytes changed during a fix.

### Rebuild from source (expensive, corrective)

Refresh only ever knows the current session, so across dozens of sessions a digest slowly sheds facts that are old but still true. Rebuild re-derives the digest **from the page**.

**Triggers:** the page has no `digest-updated::` and is being loaded or saved (lazy backfill); `digest-updated::` is more than 30 days behind `last-updated::` (**suggest** — never spend silently); brain-doctor's guided backfill; explicit "rebuild digest for X".

**Procedure — project-shaped pages** (has `## Overview`, `## Current Plan`, and `## Session Log` by name — the standard project template):

1. Read the property block and `## Overview` → Identity.
2. Read `## Current Plan` → Now, and `next::`.
3. Read `## Decisions` — headline lines only → Binding.
4. `brain tail <page> "Session Log" --entries 3 --max 4096` — recent entries carry more signal per byte. Stop once the slots are filled.
5. Never read the project's `___SessionArchive` page: it carries no digest, and the Map's `Archive` clause already points to it.
6. Write the properties and prose slots with Edit, then `brain digest <page> --apply`.

**Procedure — task-shaped pages (no fixed template):** task pages often have none of the project headings; one oversized `## Notes` can be most of the file. Branch instead:

1. Read the property block.
2. **`brain sections <page>`** — every real section, measured, in one call.
3. **Read the largest one or two sections**, ≤ 8 KB each: `brain read`, or over the cap `brain tail <page> "<section>" --max 8192` (newest first).
4. **Identity** from the smallest, most stable section (often `## Overview`); **Now** from the newest dated content in the largest.
5. **Skip Binding, Hazard and the free slot** when nothing supports them; task digests run thin by design.
6. Never read a `___SessionArchive` page: it carries no digest, and the Map's `Archive` clause already points to it.
7. Write the prose with Edit, then `brain digest <page> --apply`.

**Never read the whole file in a single Read during a rebuild** — that is the cost this feature exists to avoid, on a task page most of all, since a task page's one oversized section is usually most of the file.
