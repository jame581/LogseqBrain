# Escalation — lazy retrieval beyond the digest

The digest is a floor, not a ceiling. When the conversation needs something it does not carry, fetch it narrowly and out loud.

## The ladder

| Level | Action | Command | Announce? |
|---|---|---|---|
| 0 | Digest, already loaded | — | — |
| 1 | Consult the Map: does this even exist on this page? | — | no |
| 2 | Count, then hits | `brain search "<term>" --page <P>` | **yes** |
| 3 | Bounded windows around hits (≤ 8 KB total, enforced) | `brain search "<term>" --page <P> [--section S] --context 10` | yes |
| 4 | Whole section (≤ 8 KB, enforced) | `brain read <P> "<section>"`, or `brain tail` for the newest entries | yes |
| 5 | Whole page | Read it only after the user agrees, stating its size from `brain sections` | **ask first** |

## Rules

1. **Never skip a level.** If level 2 answers the question, stop there. Most questions end at level 2.
2. **Announce from level 2 up:** *"checking the Session Log for the Hangfire decision…"*
3. **Level 5 needs explicit consent, with the size stated:** *"That means reading the whole 184 KB page — want me to?"*
4. **Counts-only is a signal, not a failure.** When `search` returns counts instead of hits, narrow the term, or pick the section that structurally answers the question and pass `--section`. "Why did we…" → `Decisions`; "when did we…" → `Session Log`. Never widen the read instead.
5. **Quote the `coverage:` line** of every read you reason from.
6. **Escalation is read-only.** It never writes, refreshes or rebuilds anything.

## When the page contradicts the digest

The page wins; the digest is derived and disposable. Say so plainly, answer from the page, and suggest a save (which refreshes the digest) or a rebuild (`skills/_shared/digest.md`). Never patch the digest mid-conversation.
