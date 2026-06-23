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
- **detection:** part of the general phantom-link scan — compare every `[[target]]` against the set of real pages (filenames with `___`→`/`):
  ```
  ls pages/*.md | sed 's#pages/##; s/\.md$//; s/___/\//g' | sort -u > /tmp/real.txt
  grep -rohE "\[\[[^]]+\]\]" pages/ journals/ | sed 's/^\[\[//; s/\]\]$//' | grep -v '^file:///' | sort -u > /tmp/links.txt
  comm -23 /tmp/links.txt /tmp/real.txt   # phantom targets
  ```
- **remediation:**
  - Obvious typo → fix to the correct page (`[[Projects/Unicorn]]` → `[[Projects/Unicorn-Globus]]`).
  - Description or internal slug → unbracket to prose, or backtick if it's a literal token.
  - A reference to a page that simply doesn't exist **yet** (a real ticket ID, a planned page) → **leave it** unless the user says otherwise. A missing-page link is a valid forward-reference, not always a bug. List these separately in the report.

## After repair — verify

- Re-run each detection; expect zero (minus intentional forward-references).
- Per-file backtick parity: every file should have an **even** number of `` ` `` characters (odd = a broken inline-code span introduced by the fix).
```
for f in pages/*.md journals/*.md; do c=$(grep -o '`' "$f" | wc -l); [ $((c%2)) -ne 0 ] && echo "ODD: $f"; done
```
