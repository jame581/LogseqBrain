# Graph Hygiene Rules — canonical catalog

The single source of truth for the format violations that corrupt a Logseq brain graph. Two consumers read this file:

- **`skills/brain-doctor/SKILL.md`** — iterates every rule whose `enforced-at` includes `scan` (reactive whole-graph lint + repair).
- **`skills/brain-save/SKILL.md`** — applies rules whose `enforced-at` includes `compose` and `auto-fixable` is `yes`/`safe-only` as a write-time self-check on its own composed text (it never runs the `report` rules).

The narrative "why" and the compose-time guidance live in `skills/_shared/logseq-format.md`; this file is the operational catalog.

## Rule entry schema

Each rule below has:

- **id** — stable slug (used by both consumers; never rename).
- **severity** — `breaks-render` | `phantom-page` | `data-quality`.
- **enforced-at** — `compose` (brain-save can prevent it) and/or `scan` (brain-doctor finds it).
- **auto-fixable** — `yes` (safe to bulk-fix), `safe-only` (auto-fix the unambiguous subset, report the rest), `report` (never auto-write; surface with a suggestion).
- **detection** — the grep/procedure (run from the graph root, over `pages/` and `journals/`).
- **remediation** — the transform, or the report guidance.

Detections that match inside backticks or `{{ }}` are false positives for the `#`/link rules (Logseq does not linkify code/macro content) — mask inline-code and macro spans before counting, as noted per rule.

---

## `code-in-braces`
- **severity:** breaks-render
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `grep -rohE "\{\{[^}]*\}\}" pages/ journals/ | sort | uniq -c | sort -rn`
  Confirm it's not an intentional macro: check `logseq/config.edn` for a non-empty `:macros {…}`, and that none are real macros (`{{query`, `{{embed`, `{{video`, `{{renderer`, `{{cards`, `{{function`, `{{namespace`, `{{tutorial`). If `:macros {}` and none match, every hit is mis-wrapped code.
- **remediation:** `{{X}}` → `` `X` ``. Two edge cases the bulk pass must skip and you hand-fix:
  - Span contains a backtick (e.g. `` Expression`1 ``): use a double-backtick fence `` `` … `` ``.
  - Span contains a literal `{` or `}` (Mongo query `countDocuments({ … })`, a CSS rule, a `{list}` template): the simple regex won't match it; reconstruct the literal braces (a bad save sometimes *doubled* them, `{`→`{{`) and wrap the whole thing in backticks.

  Bulk regex (handles the common case): replace `\{\{([^{}]*)\}\}` → `` `\1` `` (and `` `` \1 `` `` when the captured group contains a backtick). Leave empty `{{}}` alone.

## `bare-hash-tag`
- **severity:** phantom-page
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `grep -rnE "(^|[[:space:]])#([0-9]{1,4}|[0-9A-Fa-f]{6})\b" pages/ journals/ | grep -vE "#\[\["`
  Hits already inside backticks or `{{ }}` are false positives (Logseq won't linkify code/macro content) — mask those before counting.
- **remediation:** `#44` → `` `#44` ``, `#0066CC` → `` `#0066CC` ``. **Never touch `#[[Page Name]]`** (valid tag-link) or `#` already inside backticks/`{{ }}`. Mask inline-code spans (`` `…` ``), macro spans (`{{…}}`), and `#[[…]]` first, transform on the remainder, then unmask.

## `unnamespaced-link`
- **severity:** phantom-page
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `grep -rnE "\[\[(CRMGM|GLOPRICE)-[0-9]+\]\]" pages/ journals/`
  (Add other task prefixes the graph uses.)
- **remediation:** `[[CRMGM-1234]]` → `[[Tasks/CRMGM-1234]]`. Regex `\[\[(CRMGM-\d+|GLOPRICE-\d+)\]\]` → `[[Tasks/\1]]`. Already-namespaced `[[Tasks/…]]` won't match. Bare *text* mentions (no `[[ ]]`) are not links — leave them.

## `file-link`
- **severity:** phantom-page
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `grep -rnE "\[\[file:///" pages/ journals/`
- **remediation:**
  - Labeled `[[file:///URL][LABEL]]` → `[LABEL](file:///URL)`.
  - Bare `[[file:///URL]]` → `[<basename>](file:///URL)` (use the last path segment as the label), or backtick the path if a link isn't wanted.

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
- **detection:** single-colon `key: value` where the key is one lowercase-dashed token at property position. Grep:
  `grep -rnE "^[[:space:]-]*[a-z][a-z0-9-]*: " pages/ journals/`
  The single-token-no-space key excludes prose ("Root cause:" has a space in the phrase), leading `[a-z]` excludes times ("18:18") and capitalized prose. A URL in *key position* (`https://…`) is excluded too, but note a URL *value* line (`- url: https://…`) still matches the grep — it lands in the report tier below, never auto-fixed. Open vocabulary — do NOT use a fixed key whitelist (a real graph invents ~60 keys).
- **remediation:** `key:` → `key::`, applied by confidence tier:
  - **page-top property block** (lines before the first `- ##` heading): unambiguously properties → **auto-fix**. This is the only tier `safe-only` auto-fixes.
  - **inline** bullet (anywhere below the first heading): ambiguous — a prose line like `- status: we are blocked` would be silently turned into a property → **report with suggestion, never auto-write**. If the key also appears as `key::` elsewhere in the graph, surface that as a higher-confidence suggestion, but still leave the decision to the user.

## `broken-link`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:** real-page set (filenames `___`→`/`) vs. all `[[…]]` targets — run this **once** per scan session; the result feeds `description-link` (prose/slug sub-case) and `unnamespaced-link` (missing-namespace sub-case):
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
- **detection:** within `## Session Log` (project pages) and `## Activity` (journals) only, normalize each bullet (strip leading `HH:mm`/`yyyy-MM-dd` prefix + indentation) and flag **exact** repeats. Procedure: read each section, normalize bullets, group, report any group with count > 1. Optionally surface ≥0.9-similar pairs as "possible" (report, lower confidence).
- **remediation:** report the duplicate group(s); the user chooses which to drop. No auto-removal.

## `structural-integrity`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:**
  - **Missing required properties:** each `pages/Projects___*.md` must have `type::`, `status::`, `created::`, `last-updated::` in its page-top property block (the keys `brain-init` seeds). Task pages have no fixed template → skip this check for them. Runnable check:
    ```
    for f in pages/Projects___*.md; do for k in type status created last-updated; do grep -qE "^$k:: " "$f" || echo "$f missing $k::"; done; done
    ```
  - **Empty / placeholder-only sections:** a `## Heading` whose only child is an italic `_stub_` (e.g. `_No active plan yet._`, `_Session entries are added by brain-save._`) or nothing.
- **remediation:** report. One **optional** safe suggestion: backfill a missing `last-updated::` from the newest `## Session Log` date (offer, do not auto-apply).

## After repair — verify

- Re-run each detection; expect zero (minus intentional forward-references).
- Per-file backtick parity: every file should have an **even** number of `` ` `` characters (odd = a broken inline-code span introduced by the fix).
```
for f in pages/*.md journals/*.md; do c=$(grep -o '`' "$f" | wc -l); [ $((c%2)) -ne 0 ] && echo "ODD: $f"; done
```
