# Graph Hygiene Rules — canonical catalog

The single source of truth for the format violations that corrupt a Logseq brain graph. Two consumers read this file:

- **`skills/brain-doctor/SKILL.md`** — iterates every rule whose `enforced-at` includes `scan` (reactive whole-graph lint + repair).
- **`skills/brain-save/SKILL.md`** — follows the compose-time rules while composing, including `jira-markup`'s "fence it up front" instruction. After writing, it runs `brain check` on every file it wrote. That reports every mechanical rule, plus `stale-map`, `map-label`, `oversized-digest` and a missing Map, on the lines the save added (see "Post-write verify" below). The whole-graph judgment rules (`description-link`, `duplicate-entry`, `structural-integrity`) stay brain-doctor's.

The narrative "why" and the compose-time guidance live in `skills/_shared/logseq-format.md`; this file is the operational catalog.

**Detection lives in the helper.** Every mechanical rule and every digest rule below is implemented in `skills/_shared/lib/lint.awk` / `map.awk` and reported by `brain lint` (whole files) or `brain check` (only lines a save added). Detection is validated against Logseq's own parse cache (`tools/oracle/`), not against a guess about the parser. The `detection:` lines below say what the helper reports; they are not commands to retype.

## Rule entry schema

Each rule below has:

- **id** — stable slug; it is the rule's `## …` section heading (the backtick-wrapped slug shown on each entry below), not a separate `id:` line; used by both consumers; never rename.
- **severity** — `breaks-render` | `phantom-page` | `data-quality`.
- **enforced-at** — `compose` (brain-save can prevent it) and/or `scan` (brain-doctor finds it).
- **auto-fixable** — `yes` (safe to bulk-fix), `safe-only` (auto-fix the unambiguous subset, report the rest), `report` (never auto-write; surface with a suggestion).
- **detection** — the grep/procedure (run from the graph root, over `pages/` and `journals/`).
- **remediation** — the transform, or the report guidance.

Detections that match inside backticks or `{{ }}` are false positives for the `#`/link rules (Logseq does not linkify code/macro content) — mask inline-code and macro spans before counting, as noted per rule. Content inside ``` … ``` fenced code blocks is never linkified or macro-expanded by Logseq either, so a hit *inside* a fence is a false positive for **all** rules, not just `jira-markup` — mask fenced blocks (in addition to inline-code and macro spans) before counting or transforming, for every rule below.

---

## `code-in-braces`
- **severity:** breaks-render
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `brain lint` → `code-in-braces`: a `{{` outside inline code and fences that does not open a Logseq macro (`query`, `embed`, `video`, `renderer`, `cards`, `function`, `namespace`, `tutorial`). If `logseq/config.edn` defines custom `:macros`, hits naming them are intentional.
- **remediation:** `{{X}}` → `` `X` ``. The bulk pass must skip fenced blocks — mask them before the regex replace and unmask after. Two edge cases the bulk pass must skip and you hand-fix:
  - Span contains a backtick (e.g. `` Expression`1 ``): use a double-backtick fence `` `` … `` ``.
  - Span contains a literal `{` or `}` (Mongo query `countDocuments({ … })`, a CSS rule, a `{list}` template): the simple regex won't match it; reconstruct the literal braces (a bad save sometimes *doubled* them, `{`→`{{`) and wrap the whole thing in backticks.

  Bulk regex (handles the common case): replace `\{\{([^{}]*)\}\}` → `` `\1` `` (and `` `` \1 `` `` when the captured group contains a backtick). Leave empty `{{}}` alone.

## `bare-hash-tag`
- **severity:** phantom-page
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `brain lint` → `bare-hash-tag`. Logseq makes a tag of `#` followed by any character except whitespace, `#`, `[`, a backtick, `,`, `"` or `*` (verified), or `]` `.` `;` `:` `!` `?` `'` (assumed until the fixture-graph check; `]` covers `[[C#]]`), **whatever precedes the `#`**. Measured against Logseq's parse cache on 2026-09-11: `C#-parity` → page `-parity`, `C#)` → `)`, `PKCS#12` → `12`, CSS `#image` → `image`. The previous rule caught 0 of those 6. Masked first: fenced blocks, inline code, whole markdown links (`[#65](url)` is not a tag), bare URLs, `#[[…]]`, heading markers. Each hit is classified `number`, `hex`, `after-word`, `word` or `punct`.
- **remediation:** `#44` → `` `#44` ``, `#0066CC` → `` `#0066CC` ``. Punctuation-adjacent hits are in scope — `(#1)` → `` (`#1`) ``, `#2–#5` → `` `#2`–`#5` ``. **Never touch `#[[Page Name]]`** (valid tag-link) or `#` already inside backticks/`{{ }}`/fenced blocks. Mask inline-code spans (`` `…` ``), macro spans (`{{…}}`), fenced code blocks (``` … ```), and `#[[…]]` first, transform on the remainder, then unmask. `after-word` hits: backtick the token (`` `C#`-parity ``) or rephrase (`C# parity`). `word` hits (e.g. a CSS selector): backtick them.

## `unnamespaced-link`
- **severity:** phantom-page
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `brain lint` → `unnamespaced-link`: any `[[ABC-123]]` (uppercase prefix, dash, digits).
- **remediation:** `[[CRMGM-1234]]` → `[[Tasks/CRMGM-1234]]`. Regex `\[\[(CRMGM-\d+|GLOPRICE-\d+)\]\]` → `[[Tasks/\1]]`. Already-namespaced `[[Tasks/…]]` won't match. Bare *text* mentions (no `[[ ]]`) are not links — leave them.

## `file-link`
- **severity:** phantom-page
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `brain lint` → `file-link`: `[[file:` outside inline code and fences.
- **remediation:**
  - Labeled `[[file:///URL][LABEL]]` → `[LABEL](file:///URL)`.
  - Bare `[[file:///URL]]` → `[<basename>](file:///URL)` (use the last path segment as the label), or backtick the path if a link isn't wanted.

## `jira-markup`
- **severity:** breaks-render
- **enforced-at:** compose, scan
- **auto-fixable:** report
- **detection:** `brain lint` → `jira-markup`: outside fences, an `h1.`–`h6.` heading, `{code}`, `{noformat}`, a `[~mention]`, or a bullet starting `||` (a Jira table row).
  Raw `{{x}}` outside fences is **not** this rule — it stays covered by `code-in-braces`. This rule catches the *rest* of the Jira residue that signals an unfenced draft.
- **remediation:** report — never auto-write. A Jira comment draft belongs **verbatim inside a fenced code block**: one pointer bullet above it (date, ticket, one-line gist), the fence as its child bullet, e.g.
  ```
  - Jira comment (CZ) posted 2026-06-25 — baseline script + Docker delivery:
    - ```
      h3. Shrnutí
      Dnes tři věci: … {{IMProxy}} …
      ```
  ```
  Deciding where a draft begins and ends needs judgment, so brain-doctor suggests the wrap and the user confirms. **Compose (brain-save):** when saving a Jira comment draft — signals: the user calls it a Jira comment, or the text contains `h[1-6].` headings, `{code}`/`{noformat}`, `[~mentions]`, or `{{monospace}}` spans — store it fenced as above. Never translate Jira markup to Logseq format, and never paste it raw into bullets.

## `description-link`
- **severity:** phantom-page
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:** consumes `broken-link`'s phantom-target list (no separate scan). From that list, identify entries that are prose-like or slug-like rather than real page names — e.g. `[[2026-04-16: Fixed 5.7h half-life]]` (timestamped description), `[[feedback_user_builds_locally]]` (underscore-separated slug), `[[link]]` (generic word). These are not forward-references to real pages; they are accidental linkification of prose or identifiers.
- **remediation:**
  - Description sentence accidentally bracketed → unbracket to plain prose.
  - Internal slug (underscores, no spaces, no namespace) → backtick the token instead: `` `feedback_user_builds_locally` ``.
  - Ambiguous (short word that could be a real page) → report with suggestion, do not auto-fix.

## `malformed-property`
- **severity:** data-quality
- **enforced-at:** compose, scan
- **auto-fixable:** safe-only
- **detection:** `brain lint` → `malformed-property`: a single-colon `key: value` inside the page-top property block (the auto-fix tier). Inline candidates further down may be prose; surface them for review with `grep -rnE "^[[:space:]-]*[a-z][a-z0-9-]*: " pages/ journals/`.
- **remediation:** `key:` → `key::`, applied by confidence tier:
  - **page-top property block** (lines before the first `- ##` heading): unambiguously properties → **auto-fix**. This is the only tier `safe-only` auto-fixes.
  - **inline** bullet (anywhere below the first heading): ambiguous — a prose line like `- status: we are blocked` would be silently turned into a property → **report with suggestion, never auto-write**. If the key also appears as `key::` elsewhere in the graph, surface that as a higher-confidence suggestion, but still leave the decision to the user.

## `broken-link`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:** `brain lint` reports `[[Projects/…]]` / `[[Tasks/…]]` targets with no page file, as tier `warn`. That is the most common save-time error: 71 links in 13 of 16 saves measured. The full phantom-target list that `description-link` and `unnamespaced-link` consume still comes from this procedure:
  ```
  ls pages/*.md | sed 's#pages/##; s/\.md$//; s/___/\//g' | sort -u > /tmp/real.txt
  grep -rohE "\[\[[^]]+\]\]" pages/ journals/ | sed 's/^\[\[//; s/\]\]$//' | grep -v '^file:///' | sort -u > /tmp/links.txt
  comm -23 /tmp/links.txt /tmp/real.txt
  ```
  Do **not** re-run this command inside `description-link` or `unnamespaced-link` — they consume the two lists from this single run. The `/tmp/*` paths are illustrative scratch — use any temp/host-scratchpad location (on Windows Git Bash `/tmp` resolves).
- **remediation:** report. Sub-classify each phantom target: (a) missing namespace (e.g. `[[CRMGM-x]]`) → handled by `unnamespaced-link` (auto-fix); (b) prose-like or slug-like target → handled by `description-link` (unbracket/backtick); (c) fuzzy-close to an existing page → likely typo → report **with the suggested match**; (d) no close match → forward-reference → report under "intentional? leaving as-is." Never auto-delete a link.

## `duplicate-entry`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:** within `## Session Log` (project pages) and `## Activity` (journals) only. Normalize each bullet by stripping indentation and the leading `- ` marker **only** — keep any `HH:mm` time prefix (two saves of the same project at different times are two events, not duplicates) and keep the `yyyy-MM-dd` date prefix. **Exclude property lines** (after stripping, lines matching `^[a-z][a-z0-9-]*:: `) — repeating `skills-used::`/`related-tickets::` values across sessions is expected, not duplication. Group the remaining normalized bullets and flag any group with count > 1 (exact repeats only).
- **remediation:** report the duplicate group(s); the user chooses which to drop. No auto-removal.

## `structural-integrity`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:**
  - **Missing required properties:** each `pages/Projects___*.md` must have `type::`, `status::`, `created::`, `last-updated::` in its page-top property block (the keys `brain-init` seeds). Task pages have no fixed template, but each `pages/Tasks___*.md` must carry `status::` (one of `active | blocked | done`) in its page-top block:
    ```
    for f in pages/Tasks___*.md; do grep -qE "^status:: (active|blocked|done)$" "$f" || echo "$f missing/invalid status::"; done
    ```
    Runnable check:
    ```
    for f in pages/Projects___*.md; do for k in type status created last-updated; do grep -qE "^$k:: " "$f" || echo "$f missing $k::"; done; done
    ```
  - **Empty / placeholder-only sections:** a `## Heading` whose only child is an italic `_stub_` (e.g. `_No active plan yet._`, `_Session entries are added by brain-save._`) or nothing.
- **remediation:** report. One **optional** safe suggestion: backfill a missing `last-updated::` from the newest `## Session Log` date (offer, do not auto-apply).

  For missing task `status::`, offer the **guided batch backfill**: list every flagged task page with the date of its most recent Session Log entry; propose `done` for each, **except** propose `active` when the task is *visibly active* — a session entry within the last 30 days, **or** the task is listed in any project page's `## Active Tasks` / `## Current Plan` section. Present the full proposal table, apply on one confirmation (surgical Edit inserting the `status::` line into each page-top block). Never write without the confirmation.

## `relative-link`
- **severity:** phantom-page
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `brain lint` → `relative-link`: a markdown link whose target is not a URL, `mailto:`, an anchor or `assets/`. For example, `[design](docs/specs/x.md)` makes Logseq create a page named after the target (two live cases on 2026-09-11).
- **remediation:** keep the label and backtick the path: ``design (`docs/specs/x.md`)``. For a real local file, use a `file:///` markdown link instead.

## `new-property-key`
- **severity:** phantom-page
- **enforced-at:** compose, scan
- **auto-fixable:** report
- **detection:** `brain lint` → `new-property-key`: a `key::` used nowhere else in the graph and not one of the plugin's own keys. With `:property-pages/enabled? true`, every key becomes a Logseq page: 80 on the live graph on 2026-09-11, many of them one-offs.
- **remediation:** report. Suggest an existing key (`next-action::`, `open-questions::`, …) or plain prose. Whether the graph should turn property pages off is a separate, future graph-policy decision.

## `missing-digest`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:** a project or task page carrying no digest, **or one whose `## Digest` section has no `Map:` bullet** — the Map is a required slot (`skills/_shared/digest.md`), so a digest missing it is a missing digest, not a shorter one. Excludes session-archive pages and the singletons. `brain lint` (through `map.awk`) reports it for every digest-bearing page: no `## Digest`, or a Digest with no `Map:` line.
- **remediation:** report each page with its byte size, largest first (biggest pages pay back a digest soonest). Offer the rebuild-from-source procedure in `skills/_shared/digest.md`. **Report-tier**: building a digest is a judgment call with real token cost — never auto-spent. For a whole-graph pass use brain-doctor's guided digest backfill.

## `stale-digest`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:** `digest-updated::` more than 30 days behind `last-updated::` on the same page. `brain digest <page>` prints `drift: N days`; `brain lint` reports `stale-digest` when N > 30.
- **remediation:** report both dates and the gap; suggest rebuild-from-source. Never rebuild without confirmation — a rebuild reads real content and costs real tokens.

## `stale-map`
- **severity:** data-quality
- **enforced-at:** scan, and every save via `brain check`
- **auto-fixable:** yes, by `brain digest <page> --apply`, which rewrites only the Map line (a Remap)
- **detection:** `brain lint` / `brain digest <page>`: the Map line differs from what the helper computes from the page now. The finding names each clause whose figure no longer matches (`Session Log | 147 KB (62 entries) → 151 KB (62 entries)`).
- **remediation:** `brain digest <page> --apply`. Never hand-edit the Map.

## `map-label`
- **severity:** data-quality
- **enforced-at:** scan, and every save via `brain check`
- **auto-fixable:** yes (the same Remap)
- **detection:** a Map clause whose label is neither a real heading nor its 40-byte cut, e.g. `Session 08-12` for `Session 2026-08-12 — solved…` (7 of 66 digests measured on the live graph). A label that doesn't resolve can't lead back to its section.
- **remediation:** `brain digest <page> --apply`.

## `oversized-digest`
- **severity:** data-quality
- **enforced-at:** compose, scan
- **auto-fixable:** safe-only
- **detection:** the `## Digest` section exceeds 800 bytes, or any digest property value exceeds 120 **bytes**. `brain digest <page>` prints `over:` lines, and `brain lint` reports `oversized-digest`: the section over 800 bytes, or `focus::` / `next::` / `open::` over 120 bytes (all counted in bytes by the helper).
- **remediation:** the safe subset is **compose-time only** — `brain-save` recompresses its own composed digest before writing it: drop the free slot first, then shorten Binding and Hazard; **never drop the Map**. At **scan** time this rule is **report-only**: trimming content already on disk is never safe to automate, because the excess may be the only place something is recorded. Same scoping discipline as `malformed-property`.

## Post-write verify (scoped)

After all writes in an operation, run `brain check <every file written>`. It lints only the lines added since the baseline that `brain sections <page> --baseline <other files>` recorded before the first Edit. It prints `check <file>: N new (E error, W warn), P pre-existing` and exits 1 on any new error-tier finding. Fix those with Edit and re-run `check` on that file. Warn-tier findings go in the confirmation to the user. Pre-existing findings belong to brain-doctor: mention them, don't silently fix them.

## After repair — verify

- `brain lint <files changed>`; expect zero for the classes fixed (minus intentional forward-references).
- Per-file backtick parity: every file should have an **even** number of `` ` `` characters (odd = a broken inline-code span introduced by the fix).
```
for f in pages/*.md journals/*.md; do c=$(grep -o '`' "$f" | wc -l); [ $((c%2)) -ne 0 ] && echo "ODD: $f"; done; true
```
