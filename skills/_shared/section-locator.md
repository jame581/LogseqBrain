# Section-Targeted Reads

Project pages and journals grow to hundreds of KB. Reading one whole wastes tokens and invites confabulation. This pattern — used by `brain-load`, `brain-save`, `brain-status`, and digest rebuilds — measures first, reads only what is needed, and always states what it left out.

## Budgets are in bytes, not lines

Measured on a real brain graph (2026-07-25): bullets average **195 bytes**; the longest is **2,187**. A "read 80 lines" budget is therefore ~4 KB on a fat page and ~800 B on a thin one. **Line counts are not a token budget.** `limit` is only ever an upper bound on a region whose bytes you have already measured or capped.

| Operation | Budget |
|---|---|
| Brief load (digest) | ≤ 1 KB of digest content; ≤ ~2 KB actually read |
| Targeted section read | ≤ 8 KB per section |
| Full load | ≤ 24 KB soft ceiling — report the overflow, never silently truncate |
| Whole-page read | consent-gated (`skills/_shared/escalation.md`, level 5) |

## Measure before you read

`wc -c` and `grep -c` cost effectively nothing and tell you which escalation level you actually need. One Bash call:

```bash
p="pages/Projects___<Name>.md"
wc -c < "$p"                                        # whole page
grep -nE '^(- )?## ' "$p"                           # section map with line numbers
awk '/^(- )?## Session Log/{f=1} f' "$p" | wc -c    # bytes from a heading to EOF
```

Then choose: a 3 KB section is fine to read whole; an 89 KB one is not — grep inside it instead.

## Algorithm

1. **Read the property block** — `Read(offset 0, limit 10)`. Captures `type::`, `status::`, `created::`, `last-updated::`, and the digest properties `focus::` / `next::` / `open::` / `digest-updated::`.
2. **Locate sections** with Grep: `output_mode: "content"`, `-n: true`, pattern `^(- )?## (SectionName1|SectionName2|…)` — the optional `- ` (the space is inside the group) tolerates both our freshly-written `- ## Heading` and Logseq's normalized `## Heading` form (see `skills/_shared/logseq-format.md`). List every section you might need in **one** Grep call.
3. **Size each candidate section** — `next-heading-line − this-heading-line` gives the line span; measure the bytes exactly with the `awk` form above when the span looks large. Over 8 KB → do not read it whole.
4. **Read** with `offset` = the heading's line number and `limit` = the line span, capped so the read stays inside budget.
5. **State the coverage** — see below. Mandatory.
6. **Use it:** present it (brain-load, brain-status) or anchor a surgical Edit (brain-save — include enough surrounding lines for the `old_string` to be unique in the file).

## Truncation honesty (mandatory)

Any read bounded by `limit`, and any section read only in part, **must** report what it covered before you reason on it:

> `read 4 KB of 89 KB of ## Session Log (entries 47–49 of 49)`

If the bound cannot be characterized that precisely, say so instead — `read the first 4 KB of ## Session Log; the remaining 85 KB is unread`. **Never present a partial section as if it were complete.** This is the rule that stops the model confabulating the 46 entries it did not see.

Three places enforce it, at different granularities:

- **Structural** — the digest's Map bullet, at load time, before any reasoning (`skills/_shared/digest.md`).
- **Mechanical** — this rule, per read.
- **User-facing** — the coverage line in `brain-load`'s summary.

## Token-frugality target

With a digest present, a brief load is **one** Read of ≤ ~2 KB regardless of page size. Without one, a fat page's brief load is ≤ 8 KB of section-targeted reads. A save reads only the sections it will touch.

## Failure modes

- **Heading not found:** the section does not exist yet. `brain-save` appends the heading first; `brain-load` treats it as empty; the digest Map omits it rather than reporting zero.
- **Heading appears twice:** a malformed page. Surface it to the user — do not guess which one to read.
- **Section is last in the file:** there is no next heading to bound it. Measure with the `awk` form (heading → EOF) rather than guessing a line limit.
