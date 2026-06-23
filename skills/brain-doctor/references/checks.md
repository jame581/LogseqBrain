# Brain Doctor — issue catalog

Each issue class below is something Logseq turns into a **phantom page** (an empty auto-created page) or a **broken macro** when a brain skill composed it wrong. For each: what it is, why it's bad, how to detect it, how to repair it. The compose-time rules these enforce are in `skills/_shared/logseq-format.md`.

Run detections across `pages/` and `journals/`. Paths below assume the graph root is the working directory.

---

## 1. `{{ }}` macro-wrapped inline code  *(broken macro — highest impact)*

**What:** code/identifiers/file refs/CSS/DB queries wrapped in `{{ }}` instead of backticks — `{{ImageURL}}`, `{{$pull}}`, `{{null}}`, `{{Content/Products.css:225-229}}`. In Logseq `{{ }}` is *macro* syntax; with the default `:macros {}` every one renders as a broken/empty macro.

**Detect:**
```
grep -rohE "\{\{[^}]*\}\}" pages/ journals/ | sort | uniq -c | sort -rn
```
Confirm it's not an intentional macro: check `logseq/config.edn` for a non-empty `:macros {…}`, and that none are real macros (`{{query`, `{{embed`, `{{video`, `{{renderer`, `{{cards`, `{{function`, `{{namespace`, `{{tutorial`). If `:macros {}` and none match, every hit is mis-wrapped code.

**Repair:** `{{X}}` → `` `X` ``. Two edge cases the bulk pass must skip and you hand-fix:
- Span contains a backtick (e.g. `` Expression`1 ``): use a double-backtick fence `` `` … `` ``.
- Span contains a literal `{` or `}` (Mongo query `countDocuments({ … })`, a CSS rule, a `{list}` template): the simple regex won't match it; reconstruct the literal braces (a bad save sometimes *doubled* them, `{`→`{{`) and wrap the whole thing in backticks.

Bulk regex (handles the common case): replace `\{\{([^{}]*)\}\}` → `` `\1` `` (and `` `` \1 `` `` when the captured group contains a backtick). Leave empty `{{}}` alone.

---

## 2. Bare `#number` / `#hexcolor` tags  *(phantom page)*

**What:** `PR #44`, `step #3`, `#6`, or a hex color `#0066CC` written as bare text. Logseq makes each a tag → an empty page named `44` / `3` / `0066CC`. These are the "empty 2–3-character pages" users notice.

**Detect (outside code/macros):**
```
grep -rnE "(^|[[:space:]])#([0-9]{1,4}|[0-9A-Fa-f]{6})\b" pages/ journals/ | grep -vE "#\[\["
```
Hits already inside backticks or `{{ }}` are false positives (Logseq won't linkify code/macro content) — mask those before counting.

**Repair:** `#44` → `` `#44` ``, `#0066CC` → `` `#0066CC` ``. **Never touch `#[[Page Name]]`** (valid tag-link) or `#` already inside backticks/`{{ }}`. Mask inline-code spans (`` `…` ``), macro spans (`{{…}}`), and `#[[…]]` first, transform on the remainder, then unmask.

---

## 3. Un-namespaced `[[Task]]` / `[[Project]]` links  *(phantom duplicate)*

**What:** `[[CRMGM-1234]]` or `[[GLOPRICE-399]]` instead of `[[Tasks/CRMGM-1234]]`. The real page file is `Tasks___CRMGM-1234.md` (= `Tasks/CRMGM-1234`), so the bare link points at a *different*, non-existent page — a phantom duplicate of a page that already exists.

**Detect:**
```
grep -rnE "\[\[(CRMGM|GLOPRICE)-[0-9]+\]\]" pages/ journals/
```
(Add other task prefixes the graph uses.)

**Repair:** `[[CRMGM-1234]]` → `[[Tasks/CRMGM-1234]]`. Regex `\[\[(CRMGM-\d+|GLOPRICE-\d+)\]\]` → `[[Tasks/\1]]`. Already-namespaced `[[Tasks/…]]` won't match. Bare *text* mentions (no `[[ ]]`) are not links — leave them.

---

## 4. `[[file://]]` links  *(phantom page titled with a path)*

**What:** `[[file:///C:/…/design.md]]` or the org-mode `[[file:///…][label]]` form. Each makes a phantom page whose title is the whole file path.

**Detect:**
```
grep -rnE "\[\[file:///" pages/ journals/
```

**Repair:**
- Labeled `[[file:///URL][LABEL]]` → `[LABEL](file:///URL)`.
- Bare `[[file:///URL]]` → `[<basename>](file:///URL)` (use the last path segment as the label), or backtick the path if a link isn't wanted.

---

## 5. Description / slug links  *(junk page — needs judgment)*

**What:** a sentence-like string or an internal slug bracketed as a link — `[[2026-04-16: Fixed 5.7h half-life]]`, `[[feedback_user_builds_locally]]`, `[[link]]` (illustrative text), `[[Projects/Unicorn]]` (typo for `[[Projects/Unicorn-Globus]]`).

**Detect:** part of the general phantom-link scan — compare every `[[target]]` against the set of real pages (filenames with `___`→`/`):
```
ls pages/*.md | sed 's#pages/##; s/\.md$//; s/___/\//g' | sort -u > /tmp/real.txt
grep -rohE "\[\[[^]]+\]\]" pages/ journals/ | sed 's/^\[\[//; s/\]\]$//' | grep -v '^file:///' | sort -u > /tmp/links.txt
comm -23 /tmp/links.txt /tmp/real.txt   # phantom targets
```

**Repair (judgment required):**
- Obvious typo → fix to the correct page (`[[Projects/Unicorn]]` → `[[Projects/Unicorn-Globus]]`).
- Description or internal slug → unbracket to prose, or backtick if it's a literal token.
- A reference to a page that simply doesn't exist **yet** (a real ticket ID, a planned page) → **leave it** unless the user says otherwise. A missing-page link is a valid forward-reference, not always a bug. List these separately in the report.

---

## After repair — verify

- Re-run each detection; expect zero (minus intentional forward-references).
- Per-file backtick parity: every file should have an **even** number of `` ` `` characters (odd = a broken inline-code span introduced by the fix).
```
for f in pages/*.md journals/*.md; do c=$(grep -o '`' "$f" | wc -l); [ $((c%2)) -ne 0 ] && echo "ODD: $f"; done
```
