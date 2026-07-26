# Section-Targeted Reads

Project pages and journals grow to hundreds of KB. Reading one whole wastes tokens and invites confabulation. This pattern — used by `brain-load`, `brain-save`, `brain-status`, and digest rebuilds — measures first, reads only what is needed, and always states what it left out.

## Budgets are in bytes, not lines

Measured on a real brain graph (2026-07-25): bullets average **195 bytes**; the longest is **2,187**. A "read 80 lines" budget is therefore ~4 KB on a fat page and ~800 B on a thin one. **Line counts are not a token budget.** `limit` is only ever an upper bound on a region whose bytes you have already measured or capped.

| Operation | Budget |
|---|---|
| Brief load (digest) | ≤ 1 KB of digest content; ≤ ~2 KB actually read |
| Today's journal, on load (this project's mention(s), shrunk to fit) | **Target** ~2 KB via shrink-to-fit (`skills/brain-load/SKILL.md` step 4), not a hard ceiling — the grep is whole-file, keyed on `^[[:space:]]*- \[\[Projects/<Name>\]\]`, never scoped to a `## Sessions` heading (10 of 69 real journals lack one entirely, 8 of those still carry real session bullets orphaned under a bare `-`). All matches are read, then the oldest are dropped one at a time until under budget — a single oversized match is still read whole rather than dropped to zero. Measured: `2026_04_25` shrinks from 8,468 B (4 matches, one project) to 1,248 B (the most recent 1). Reading the whole journal file, unbounded, can run to **10,152 B** on the reference graph — this is why the grep is targeted, never a whole-file read. |
| Targeted section read | ≤ 8 KB per section |
| Full load | ≤ 24 KB soft ceiling — Session Log tail is byte-bounded (last 10 entries *or* ~8 KB, whichever is smaller — see "Reading a section's tail"); **state the measured total and ask before reading** when it would exceed the ceiling, then report any remaining overflow rather than truncating silently |
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

1. **Read the property block** — `Read(offset 0, limit 10)` is the *starting* bound, not a guarantee. It captures `type::`, `status::`, `created::`, `last-updated::` and the digest properties `focus::` / `next::` / `open::` / `digest-updated::` **on a page whose property block fits in 10 lines** — true of the project template, not guaranteed anywhere else. Task pages have no fixed template and carry arbitrary extra properties, so a digest property can sit below line 10. **A property absent from a bounded read is not an absent property** — if the read ends without reaching a non-property line (a blank line or the first `- ` bullet), the block ran past the bound: re-read with a larger `limit`. Never conclude `digest-updated::` is missing from a read that never reached the end of the block; that is how a healthy page gets reported as un-backfilled.

   **If you also need the `## Digest` section, use `limit 20`, not `limit 10`.** The digest sits between the property block and `## Overview`, and its **Map bullet is always last** — a `limit 10` read silently truncates it away, which loses the one thing that tells you what you have not read. When in doubt, read 20.

   **Raising the number again is not a fix — check instead.** Task pages have no fixed template, so their property blocks are unbounded: enough extra properties and a `limit 20` read lands past the end of `## Digest` entirely, returning several plausible-looking digest bullets and no Map. **The read must contain a `Map:` bullet; if it does not, treat the bound as too short, not the page as Map-less** — re-read with a larger `limit`, or `grep -nE '^(- )?## '` for the exact section span and read from there. Never present a digest whose Map you did not see — this is a check every caller of this step must make, not a suggestion.

   **Terminal case: the page can genuinely lack a Map.** If a re-read bounded to the exact `## Digest` span (the heading line found by the grep above, through to the line before the next `## ` heading — i.e. the whole section, not a guess at a bigger `limit`) still shows no `Map:` bullet, the page is not under-read; it lacks one. Say so, treat that page's coverage as unknown until a rebuild, and offer to build or rebuild the digest per `skills/_shared/digest.md`. A bound wider than the section's own measured span cannot recover a bullet that was never written — stop re-reading and report instead.
2. **Locate sections** with Grep: `output_mode: "content"`, `-n: true`, pattern `^(- )?## (SectionName1|SectionName2|…)` — the optional `- ` (the space is inside the group) tolerates both our freshly-written `- ## Heading` and Logseq's normalized `## Heading` form (see `skills/_shared/logseq-format.md`). List every section you might need in **one** Grep call.
3. **Size each candidate section** — `next-heading-line − this-heading-line` gives the line span; measure the bytes exactly with the `awk` form above when the span looks large. Over 8 KB → do not read it whole.
4. **Read** with `offset` = the heading's line number and `limit` = the line span, capped so the read stays inside budget.
5. **State the coverage** — see below. Mandatory.
6. **Use it:** present it (brain-load, brain-status) or anchor a surgical Edit (brain-save — include enough surrounding lines for the `old_string` to be unique in the file).

## Reading a section's tail

The algorithm above reads *forward* from a heading — fine when the whole section is small, but `digest.md` mandates reading `## Session Log` **tail-first** (recent entries carry more signal per byte), and both brain-load's no-digest fallback and full mode need a **byte-bounded** tail: fallback's is last 3 entries **or ~4 KB, whichever is smaller**; full mode's is last 10 entries **or ~8 KB (the per-section cap above), whichever is smaller**. A count alone assumes average-sized bullets — measured on a real page, three recent entries averaging ~3 KB each cost 9.1 KB, blowing straight past any stated ceiling. Neither is a forward read, and getting the tail of a large section without reading it whole needs its own recipe.

**Scope the entry search to the section, never the whole file.** A page-wide grep for the entry pattern also finds dated bullets in `## Decisions` and dated headings elsewhere — sections that are not the one whose tail you were asked for. On a real page (`Projects___SELOS.md`) an unscoped grep returns 19 dated-shaped lines; `## Session Log` itself holds 12. And on a page where `## Session Log` is not the *last* section (true on several real task pages — `## Notes` follows it), an unscoped "last N" silently returns entries from whatever section happens to be last, not the one asked for. Always derive the target section's own line range first — the section map the main algorithm already computes — and confine every grep in this recipe to it:

1. **Get the section's line range from the section map** (already computed by step 2/3 of the main algorithm above): `lineno` = the heading's line; `endline` = the next heading's line minus 1, or the file's last line if this section is last in the file.
2. **Find every entry-start line inside that range, cheaply** — scope the grep to `lineno+1`–`endline`, not the whole file:
   ```bash
   p="pages/Projects___<Name>.md"
   sed -n "$((lineno+1)),${endline}p" "$p" \
     | grep -nE '^[[:space:]]*- (#{3,6} +)?\[?\[?[0-9]{4}-[0-9]{2}-[0-9]{2}'
   ```
   Use the widened pattern verbatim from `skills/_shared/digest.md` — it matches a `### `-style dated sub-heading as well as a plain dash-bullet. Retyping a narrower version is how this regresses: the plain-dash-only form matches **zero** entries in a Session Log written entirely as `- ### yyyy-mm-dd — …` (real shape, several task pages), even though the section is full of dated entries.

   `grep -n` here numbers lines **relative to the `sed` excerpt**, not the file — recover the absolute line before using it anywhere else: `absolute = lineno + relative`.
3. **Zero matches is a real outcome — handle it explicitly, don't let it crash.** A section can legitimately hold no dated-headline bullets (an all-prose `## Notes`, a task-page catch-all whose entries don't follow the Decision Entry Template shape). Building a `start` value from an empty grep result and feeding it straight to `tail -n +"$start"` produces `tail: invalid number of lines: '+'` — a hard failure, not a graceful empty read, because `$start` is the empty string, not a number. If step 2 returns nothing:
   - **Fall back to the last ~40 lines of the section** (or the whole section if it is shorter), read via `sed -n` on the already-known `lineno`–`endline` range.
   - **State coverage in bytes only** — there is no entry count to report: *"read the last 2.1 KB of `## Notes` (18.4 KB total); no dated-entry boundary found in this section, so coverage is stated by bytes, not entry count."*
   - Do not retry with a wider file scope — that reintroduces the wrong-section failure this recipe exists to close.
4. **Take the last N line numbers (relative to the section), largest N first, then shrink to fit any byte cap the caller states.** For a plain count target ("last 3 entries," no cap), take the last 3 and move on. When a caller also states a byte cap — fallback: last 3 *or* ~4 KB, whichever is smaller; full mode: last 10 *or* ~8 KB, whichever is smaller — measure before committing to N instead of assuming the stated count is safe:
   ```bash
   sed -n "$((lineno+1)),${endline}p" "$p" \
     | grep -nE '^[[:space:]]*- (#{3,6} +)?\[?\[?[0-9]{4}-[0-9]{2}-[0-9]{2}' | tail -3   # or tail -10 for full mode
   ```
   Try the largest N first: convert the earliest of those N to an absolute line (step 2), `tail -n +<that line>` bounded at `endline` (or EOF if the section is last), and `wc -c` the result. Under the cap → read it, done — report "N of M entries". Over the cap → drop N by one, re-measure. Keep dropping until under the cap or N=1; at N=1, read it regardless of size — **never return zero entries when at least one exists** (step 3 covers the case where none do), and say so even when that single entry alone exceeds the cap. State the N you actually landed on; never assume the starting count without checking.
5. **Read from the earliest of the N lines you settled on, bounded at `endline`** (or EOF if the section is last in the file — no next heading to bound against):
   ```bash
   start=$((lineno + relative))              # relative = the earliest of the N settled on in step 4
   tail -n +"$start" "$p" | head -n $((endline - start + 1))     # or Read(offset = start-1, limit = endline - start + 1)
   ```
6. **State the coverage** as elsewhere — "read N of M entries, X KB of Y KB" — where **M is this section's own scoped entry count from step 2, never a whole-page or whole-file count** — using the byte counts from `wc -c` on the tail read versus the whole-section measurement from "Measure before you read."

Worked example (count-only, no cap), against a 49-entry, 84.6 KB `## Session Log` (the section is last in its file, and its own range already excludes everything else): the commands above return entry line numbers scoped to the section, the earliest of the last 3 is line 485 of a 514-line file, and `tail -n +485` reads 5.2 KB — the last 3 entries, at ~6% of the section's bytes, without reading the other 46 and without picking up any dated line from another section.

Worked example (byte-bounded, brain-load's fallback cap) — against a real 29.6 KB `## Session Log` (`Projects___SELOS.md`; 12 entries scoped to the section, ~2.8 KB average recent entry — **not** the 19 an unscoped whole-file grep would return on this same page, since `## Decisions` and others also carry dated bullets): the last-3 candidate (from line 176 of a 207-line file) reads **9,098 B** — already past the ~4 KB fallback cap. Dropping to the last 2 (from line 188) reads 6,271 B — still over. Dropping to the last 1 (from line 199) reads **2,815 B** — under the cap. Read that one entry and report "1 of 12 entries, 2.8 KB of 29.6 KB" rather than silently reading the 9 KB the count-only rule alone would have produced, and rather than the 19-entry denominator an unscoped grep would have claimed.

Worked example (wrong-section risk and the zero-match branch), against `Tasks___CRMGM-1904.md` (66.7 KB; `## Session Log` at line 165 is **not** the last section — `## Notes` follows it at line 300): an unscoped "last 3" grep returns three lines, all inside `## Notes`, not `## Session Log` — the wrong-section failure this recipe closes by scoping to `lineno+1`–`endline` (166–299) before searching. Scoped and using the widened pattern, that range holds **13** entries (not zero — the section's dated headlines are written as `- ### yyyy-mm-dd — …` throughout), so the tail read targets the right content: last 3 of 13. The zero-match branch (step 3) is what a narrower, retyped pattern would have hit instead — the plain-dash-only form matches nothing in this same 166–299 range even though it holds 13 real entries, which is exactly the crash step 3 exists to prevent: falling back to the section's last ~40 lines, stated in bytes, rather than feeding an empty `start` to `tail -n +`.

## Truncation honesty (mandatory)

Any read bounded by `limit`, and any section read only in part, **must** report what it covered before you reason on it:

> `read 4 KB of 89 KB of ## Session Log (entries 45–47 of 47)`

If the bound cannot be characterized that precisely, say so instead — `read the first 4 KB of ## Session Log; the remaining 85 KB is unread`. **Never present a partial section as if it were complete.** This is the rule that stops the model confabulating the 46 entries it did not see.

Three places enforce it, at different granularities:

- **Structural** — the digest's Map bullet, at load time, before any reasoning (`skills/_shared/digest.md`).
- **Mechanical** — this rule, per read.
- **User-facing** — the coverage line in `brain-load`'s summary.

## Token-frugality target

With a digest present, a brief load is **one** Read of the page — ≤ ~2 KB regardless of page size (measured: 1,474 B and 1,508 B on the two digested pages of the reference graph) — plus today's journal's mention(s) of the project, shrunk toward the journal budget above. A save reads only the sections it will touch.

Without a digest, the fallback has a **stated per-component budget**, not one soft ceiling a real page can quietly blow past: property block ≤ ~2 KB (`limit 10`) + Overview first 5 bullets ≤ ~2 KB + Current Plan ≤ 8 KB (the per-section cap above) + Session Log tail ≤ ~4 KB (byte-bounded — see "Reading a section's tail" above: last 3 entries or ~4 KB, whichever is smaller). That is ≤ ~16 KB worst case; real pages land well under it because Current Plan and Overview rarely approach their caps. Measured on a real 59.8 KB page with no digest (`Projects___SELOS.md`): property block 1.1 KB + Overview 1.0 KB + Current Plan 3.7 KB + Session Log tail 2.8 KB (1 of 12 entries, capped down from the 9.1 KB "last 3 entries" alone would have read) = **8.7 KB**. The byte cap on the tail read is what makes any of this hold — "last 3 entries" is denominated in entries, not bytes, and a page whose recent entries run large (this one averages ~3 KB each) blows through any stated ceiling without it. Raising the old ≤ 8 KB target to cover the 15 KB this same page cost before the cap existed would not have fixed anything; the tail read itself had to shrink.

**Full mode's tail needs the same shrink, at the larger per-section cap.** "Last 10 Session Log entries" is exactly as entry-denominated as the fallback's "last 3" was, and on a real page it is worse: measured live, the raw last-10 cost alone was **25.4 KB** (`Projects___Unicorn-Globus.md`, 47 entries), **27.5 KB** (`Projects___SELOS.md`, 12 entries), and **36.8 KB** (`Projects___Timinute.md`, 12 entries) — every one already past the entire 24 KB full-load ceiling, before Overview, Current Plan, Implementation, or Decisions get read at all. Full mode's tail is bounded the same way as the fallback's (last N, largest first, shrink until under the cap, never zero — see "Reading a section's tail" above), just at the full-mode-appropriate cap: **last 10 entries or ~8 KB (the per-section cap), whichever is smaller**. Bounding the same three pages this way lands the tail at **3.9 KB (1 of 47 entries)**, **6.3 KB (2 of 12)**, and **6.9 KB (2 of 12)** respectively — a real cost the rest of full mode's budget can still absorb.

Because the other full-mode components are each independently capped at ≤ 8 KB (Overview, Current Plan, Implementation, Decisions), their sum can still exceed the 24 KB ceiling even with the tail bounded. Full mode therefore **measures the total before reading** — `wc -c` on the section map is free — and when that total would exceed 24 KB, **states the figure and asks**, the same consent gate `skills/_shared/escalation.md` rule 3 already requires for a whole-page read (*"That means reading the whole 109 KB page — want me to?"*). A `load <project> full` that would cost tens of KB deserves the identical courtesy, not a silent read followed by an after-the-fact overflow note — "report the overflow" stays the honesty rule for whatever residual gap remains after the bound and the ask, not a substitute for either.

## Failure modes

- **Heading not found:** the section does not exist yet. `brain-save` appends the heading first; `brain-load` treats it as empty; the digest Map omits it rather than reporting zero.
- **Heading appears twice:** a malformed page. Surface it to the user — do not guess which one to read.
- **Section is last in the file:** there is no next heading to bound it. Measure with the `awk` form (heading → EOF) rather than guessing a line limit.
