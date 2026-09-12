# Section-Targeted Reads

Pages grow to hundreds of KB. Reading one whole wastes tokens and invites confabulation. The helper measures; you choose what to read, and every read states what it left out.

## Budgets are in bytes, not lines

Bullets in a real graph average ~195 B and reach 2 KB, so a line count is not a token budget.

| Operation | Budget |
|---|---|
| Digest load | `brain digest` (~1–2 KB) + `brain journal` (target ~2 KB) |
| Targeted section read | ≤ 8 KB per section (`brain read` enforces it) |
| Session Log tail, fallback load | last 3 entries or 4 KB, whichever is smaller (`brain tail --entries 3 --max 4096`) |
| Session Log tail, full load | last 10 entries or 8 KB (`brain tail --entries 10 --max 8192`) |
| Full load | ≤ 24 KB soft ceiling; state the total and ask before exceeding it |
| Whole page | consent-gated (`skills/_shared/escalation.md`, level 5) |

## The commands

- `brain sections <page>`: every section's line span, bytes and dated-entry count. Use it to choose, never to guess.
- `brain read <page> "<section>"`: the whole section, or a refusal stating its size.
- `brain tail <page> "<section>"`: the newest dated entries, dropping the oldest until under `--max`, never zero. With no dated entries, it takes the last bytes and says so.
- If you must use `Read` with `offset`/`limit`, take the span from `brain sections`, and still state coverage.

## Truncation honesty (mandatory)

Any partial read must report its coverage before you reason on it: `read 1 of 12 entries, 2.8 KB of 29.6 KB of ## Session Log`. The helper prints this as its `coverage:` line; quote it. **Never present a partial section as complete.** This rule stops the model confabulating the entries it did not see. It is enforced in three places:
- structurally, by the digest's Map
- mechanically, by each `coverage:` line
- to the user, by `brain-load`'s "not read" statement

## Failure modes

- **Section not found:** `brain read` / `tail` exit 2 and list the page's sections. A missing section is empty, not an error: `brain-save` creates the heading, and the Map omits it.
- **Heading appears twice:** exit 2 — a malformed page. Surface it; don't guess.
