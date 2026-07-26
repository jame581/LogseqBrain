# Escalation — lazy retrieval beyond the digest

The digest (`skills/_shared/digest.md`) is a floor, not a ceiling. When the conversation needs something the digest does not carry, fetch it — narrowly, and out loud.

## The ladder

| Level | Action | Typical cost | Announce? |
|---|---|---|---|
| 0 | Digest — already loaded | ~1 KB | — |
| 1 | Consult the Map bullet: does this even exist on this page? | 0 | no |
| 2 | Targeted grep — `rg -n "<term>" <page>` | ~100 B | **yes** |
| 3 | Bounded read around the hits (± 10 lines) — **only while the windows total ≤ 8 KB** (rule 7) | ~1–2 KB | yes |
| 4 | Whole-section read — only if that section measures ≤ 8 KB | ≤ 8 KB | yes |
| 5 | Whole-page read | up to ~109 KB | **ask the user first** |

## Rules

1. **Never skip a level.** If a grep answers the question, stop at level 2. Most questions end there.
2. **Announce from level 2 up** — *"checking the Session Log for the Hangfire decision…"*. Silent escalation reintroduces exactly the invisible-cost problem the digest exists to fix.
3. **Level 5 needs explicit consent, with the size stated:** *"That means reading the whole 109 KB page — want me to?"* This mirrors the plugin's suggestion-only discipline for writes.
4. **Measure before you climb.** `wc -c` and `grep -c` are effectively free — use the measure-before-read step in `skills/_shared/section-locator.md` to pick the level rather than guessing.
5. **Every bounded read states its coverage** (`skills/_shared/section-locator.md`). No silent truncation, at any level.
6. **Escalation is read-only.** It never triggers a write, a digest refresh, or a rebuild. Those are `brain-save`'s and `brain-doctor`'s business.
7. **Hit density changes the move.** Level 3 works when hits are *clustered*. It fails silently when they are not: a common term hits once per session entry, so 49 evenly-spaced hits have ±10-line windows that union to nearly the whole page — a whole-page read wearing a level-3 badge, announced but never consent-gated. Measured on a real fixture: a 51-hit grep expanded to 85,401 of 85,479 bytes.

   Count the hits (`rg -c`) before reading around them. When the count is high:
   - **Pick the section that structurally answers the question** — "why did we…" → `## Decisions`; "when did we…" → `## Session Log`. The Map bullet's counts tell you which is plausible.
   - **Narrow the term**, don't widen the read. Grep the specific thing, not the topic.
   - **Scope the grep to one section** using the line range from the section map.
   - Failing all that, **state the hit count and the byte cost and let the user choose** — the same courtesy level 5 requires.

   **A level-3 read whose windows exceed 8 KB is not a level-3 read.** Treat it as level 4 (and check the section cap) or level 5 (and ask). Never serially read around every hit.

## Worked example

> After `load Unicorn-Globus`, the user asks: *"Why did we drop DEV Mongo?"*

- **Level 1** — the Map says `Session Log | 87 KB (47 entries) · Active Tasks | 10 KB · Decisions | 2 KB (2)`. "Why did we…" is a Decisions question, and Decisions is 2 KB. No read yet.
- **Level 2** — announce, then count first (rule 7): `rg -c "Mongo" pages/Projects___Unicorn-Globus.md` → **40 hits**. Far too many to read around: nearly every session entry mentions it. So scope the grep to the section that answers *why* — `## Decisions`, lines 91–102 from the section map — rather than expanding 40 windows.
- **Level 3** — read that bounded span: **2,637 B**. It holds the decision entry and its `context::`. Answer, and state coverage: *"read 2.6 KB of ## Decisions around 40 total matches; 87 KB of Session Log still unread."*
- Stop. Levels 4 and 5 never run.

Total: **2.7 KB, versus 107 KB for the whole page** — measured on the real page, 2026-07-26. Note what rule 7 bought: the naive level-3 reading of 40 hits would have expanded to most of the file.

## When the digest is wrong

If escalation surfaces something that **contradicts** the digest, the page wins — the digest is derived and disposable. Say so plainly, answer from the page, and suggest a rebuild (`skills/_shared/digest.md` → "Rebuild from source"). Do not silently patch the digest mid-conversation; that is a write, and writes need confirmation.
