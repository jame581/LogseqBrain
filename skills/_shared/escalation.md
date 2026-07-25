# Escalation — lazy retrieval beyond the digest

The digest (`skills/_shared/digest.md`) is a floor, not a ceiling. When the conversation needs something the digest does not carry, fetch it — narrowly, and out loud.

## The ladder

| Level | Action | Typical cost | Announce? |
|---|---|---|---|
| 0 | Digest — already loaded | ~1 KB | — |
| 1 | Consult the Map bullet: does this even exist on this page? | 0 | no |
| 2 | Targeted grep — `rg -n "<term>" <page>` | ~100 B | **yes** |
| 3 | Bounded read around the hits (± 10 lines) | ~1–2 KB | yes |
| 4 | Whole-section read — only if that section measures ≤ 8 KB | ≤ 8 KB | yes |
| 5 | Whole-page read | up to ~109 KB | **ask the user first** |

## Rules

1. **Never skip a level.** If a grep answers the question, stop at level 2. Most questions end there.
2. **Announce from level 2 up** — *"checking the Session Log for the Hangfire decision…"*. Silent escalation reintroduces exactly the invisible-cost problem the digest exists to fix.
3. **Level 5 needs explicit consent, with the size stated:** *"That means reading the whole 109 KB page — want me to?"* This mirrors the plugin's suggestion-only discipline for writes.
4. **Measure before you climb.** `wc -c` and `grep -c` are effectively free — use the measure-before-read step in `skills/_shared/section-locator.md` to pick the level rather than guessing.
5. **Every bounded read states its coverage** (`skills/_shared/section-locator.md`). No silent truncation, at any level.
6. **Escalation is read-only.** It never triggers a write, a digest refresh, or a rebuild. Those are `brain-save`'s and `brain-doctor`'s business.

## Worked example

> After `load Unicorn-Globus`, the user asks: *"Why did we drop DEV Mongo?"*

- **Level 1** — the Map says `Decisions 12 · Session Log 89 KB`. Plausibly here; no read yet.
- **Level 2** — announce, then `rg -n "Mongo" pages/Projects___Unicorn-Globus.md` → 6 hits at lines 84, 108–112, 341.
- **Level 3** — `Read(page, offset 104, limit 14)` → the decision entry itself. Answer, and state coverage: *"read 1.2 KB around 6 matches; 89 KB of Session Log still unread."*
- Stop. Levels 4 and 5 never run.

Total: ~1.4 KB, versus 27 KB for the whole page.

## When the digest is wrong

If escalation surfaces something that **contradicts** the digest, the page wins — the digest is derived and disposable. Say so plainly, answer from the page, and suggest a rebuild (`skills/_shared/digest.md` → "Rebuild from source"). Do not silently patch the digest mid-conversation; that is a write, and writes need confirmation.
