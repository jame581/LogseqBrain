# Lint rules — detection detail (maintainers)

Not shipped, and no skill reads this file. The helper implements these detections (`skills/_shared/lib/lint.awk`, `map.awk`), `tests/cases/lint-*` and `check-*` pin them, and `tools/oracle/` validates them against Logseq's own parse cache. The shipped catalog, `skills/_shared/hygiene-rules.md`, keeps each rule's meaning, tier and repair, plus every procedure brain-doctor runs itself. Moved here verbatim in v0.12.0 (`docs/superpowers/specs/2026-09-25-v0.12.0-design.md` §3.2), as it stood at v0.11.0.

## `code-in-braces`

- **detection:** `brain lint` → `code-in-braces`: a `{{` outside inline code and fences that does not open a Logseq macro (`query`, `embed`, `video`, `renderer`, `cards`, `function`, `namespace`, `tutorial`, `cloze`, `youtube`, `youtube-timestamp`, `vimeo`, `bilibili`, `tweet`, `twitter`, `pdf`, `contents`, `zotero-imported-file`, `zotero-linked-file`). If `logseq/config.edn` defines custom `:macros`, hits naming them are intentional.

## `bare-hash-tag`

- **detection:** `brain lint` → `bare-hash-tag`. Logseq makes a tag of `#` followed by any character except whitespace, `#`, `[`, a backtick, `,`, `"`, `:`, `!`, `?` or `'` (verified against the fixture graph on 2026-09-12), or `]` (assumed; covers `[[C#]]`), **whatever precedes the `#`**. That includes `.`, `;` and `*`, all verified the same day: `#.a` → page `.a`, `#;b` → `;b`, `#**i**` → `**i**` — so `C#.NET` makes a phantom page `.NET`. One verified exception: a `*` that **closes** an already-open `**` span is emphasis, not a tag, so `**C#**` makes no page. Measured against Logseq's parse cache on 2026-09-11: `C#-parity` → page `-parity`, `C#)` → `)`, `PKCS#12` → `12`, CSS `#image` → `image`. The previous rule caught 0 of those 6. Masked first: fenced blocks, inline code, whole markdown links (`[#65](url)` is not a tag), bare URLs, `#[[…]]`, heading markers. Each hit is classified `number`, `hex`, `after-word`, `word` or `punct`.

## `relative-link`

- **detection:** `brain lint` → `relative-link`: a markdown link whose target is not a URL, `mailto:`, `file:`, an anchor, a block ref, a `[[page]]` ref or `assets/` (`lint.awk` carries the full exclusion list). For example, `[design](docs/specs/x.md)` makes Logseq create a page named after the target (two live cases on 2026-09-11).

## `new-property-key`

- **detection:** `brain lint` → `new-property-key`: a `key::` used nowhere else in the graph and not one of the plugin's own keys. With `:property-pages/enabled? true`, every key becomes a Logseq page: 80 on the live graph on 2026-09-11, many of them one-offs.

## `missing-digest`

- **detection:** a project or task page carrying no digest, **or one whose `## Digest` section has no `Map:` bullet** — the Map is a required slot (`skills/_shared/digest.md`), so a digest missing it is a missing digest, not a shorter one. Excludes session-archive pages and the singletons. `brain lint` (through `map.awk`) reports it for every digest-bearing page: no `## Digest`, or a Digest with no `Map:` line.

## `nonconvergent-map`

- **detection:** `brain lint` / `brain digest <page> --apply`: the page's own byte total sits within ~2 bytes of a KiB boundary, so recomputing the Map has no fixed point — the figure oscillates between two values each time it's measured (e.g. `1023 B` vs `1 KB`, exactly the 2 bytes the shorter label costs) because the Map line's own length feeds back into the total it describes. `--apply` **refuses to write** rather than publish a figure it knows is wrong (exit 2); `brain lint` / `brain check` report it as `nonconvergent-map` instead of silently falling back to a guess.

## `map-label`

- **detection:** a Map clause whose label is neither a real heading nor its 40-byte cut, e.g. `Session 08-12` for `Session 2026-08-12 — solved…` (7 of 66 digests measured on the live graph). A label that doesn't resolve can't lead back to its section.

## `duplicate-map`

- **detection:** `brain lint` / `brain digest <page> --apply`: the `## Digest` section carries more than one `- Map:` bullet — most plausibly a Logseq Sync merge that duplicated the block. `--apply` refuses to write (exit 2) until only one remains; `brain lint` / `brain check` report it as `duplicate-map`, naming the count.

## `oversized-digest`

- **detection:** the `## Digest` section exceeds 800 bytes, or any digest property value exceeds 120 **bytes**. `brain digest <page>` prints `over:` lines, and `brain lint` reports `oversized-digest`: the section over 800 bytes, or `focus::` / `next::` / `open::` over 120 bytes (all counted in bytes by the helper).

## `broken-link`

- That is the most common save-time error: 71 links in 13 of 16 saves measured.

## Post-write verify (scoped)

## Post-write verify (scoped)

After all writes in an operation, run `brain check <every file written>`. It prints, in order: the mechanical findings on lines added since the baseline that `brain sections <page> --baseline <other files>` recorded before the first Edit; then the digest findings for that page (`missing-digest`, `nonconvergent-map`, `stale-map`, `map-label`, `duplicate-map`, `oversized-digest`, `stale-digest`) — these are always measured over the whole page, not just the lines this save added, so a digest finding may predate this save; then, **last**, a summary line: `check <file>: N new (E error, W warn), P pre-existing`, with a `· digest: D error, M warn` suffix appended whenever digest findings exist. Example:
```
pages/Projects___X.md:19  bare-hash-tag  error  #44 (number)
pages/Projects___X.md:12  stale-map      error  Session Log | 1 KB (1 entries) → 326 B (2 entries) · page | 2 KB → 712 B
pages/Projects___X.md:7   stale-digest   warn   digest-updated 2026-08-01 is 31 days behind last-updated 2026-09-01
check pages/Projects___X.md: 1 new (1 error, 0 warn), 0 pre-existing · digest: 1 error, 1 warn
```
It exits 1 on any new error-tier finding, mechanical or digest. Fix a mechanical error with Edit and re-run `check` on that file; fix a digest error by re-running `brain digest <page> --apply` (never by hand-editing the Map — and never on a line a rotation moved verbatim, per `references/rotation.md`). Warn-tier findings go in the confirmation to the user. Pre-existing findings belong to brain-doctor: mention them, don't silently fix them. Also check per-file backtick parity on every file this save touched — an odd number of `` ` `` characters means a broken inline-code span (see "After repair — verify" below); no lint rule catches this.
