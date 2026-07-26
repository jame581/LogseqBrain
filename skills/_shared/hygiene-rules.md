# Graph Hygiene Rules — canonical catalog

The single source of truth for the format violations that corrupt a Logseq brain graph. Two consumers read this file:

- **`skills/brain-doctor/SKILL.md`** — iterates every rule whose `enforced-at` includes `scan` (reactive whole-graph lint + repair).
- **`skills/brain-save/SKILL.md`** — applies rules whose `enforced-at` includes `compose` and `auto-fixable` is `yes`/`safe-only` as a write-time self-check on its own composed text. It also follows the compose-time *composition instructions* of `compose`+`report` rules — currently only `jira-markup`, whose "Compose (brain-save):" line tells it how to format content in the first place (fence it up front) rather than fixing it after the fact. It never runs the scan-only `report` rules (`description-link`, `broken-link`, `duplicate-entry`, `structural-integrity`, `missing-digest`, `stale-digest`, `stale-map`), which need whole-graph context brain-save doesn't have. It *does* apply `oversized-digest` at compose time, recompressing its own digest before writing — see that rule's remediation. It (and later `brain-init`) also runs the `## Post-write verify (scoped)` procedure below after writing files, re-checking on disk what the compose self-check checked in memory.

The narrative "why" and the compose-time guidance live in `skills/_shared/logseq-format.md`; this file is the operational catalog.

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
- **detection:** `grep -rohE "\{\{[^}]*\}\}" pages/ journals/ | sort | uniq -c | sort -rn`
  Confirm it's not an intentional macro: check `logseq/config.edn` for a non-empty `:macros {…}`, and that none are real macros (`{{query`, `{{embed`, `{{video`, `{{renderer`, `{{cards`, `{{function`, `{{namespace`, `{{tutorial`). If `:macros {}` and none match, every hit is mis-wrapped code. Mask fenced code blocks first — `{{x}}` inside a fence is intentional verbatim content (see `jira-markup`), never a hit.
- **remediation:** `{{X}}` → `` `X` ``. The bulk pass must skip fenced blocks — mask them before the regex replace and unmask after. Two edge cases the bulk pass must skip and you hand-fix:
  - Span contains a backtick (e.g. `` Expression`1 ``): use a double-backtick fence `` `` … `` ``.
  - Span contains a literal `{` or `}` (Mongo query `countDocuments({ … })`, a CSS rule, a `{list}` template): the simple regex won't match it; reconstruct the literal braces (a bad save sometimes *doubled* them, `{`→`{{`) and wrap the whole thing in backticks.

  Bulk regex (handles the common case): replace `\{\{([^{}]*)\}\}` → `` `\1` `` (and `` `` \1 `` `` when the captured group contains a backtick). Leave empty `{{}}` alone.

## `bare-hash-tag`
- **severity:** phantom-page
- **enforced-at:** compose, scan
- **auto-fixable:** yes
- **detection:** `grep -rnP "(?<![\w/&\x60#\]])#([0-9]{1,4}|[0-9A-Fa-f]{6})\b" pages/ journals/`
  (PCRE lookbehind: `\x60` is the backtick. Not preceded by a word char, `/`, `&`, a backtick, `#`, or `]` — this also catches punctuation-adjacent tags like `(#1)`, `#2–#5`, `[#4`. If `grep -P` is unavailable, fall back to the POSIX ERE form below — note `]` must be the first character after `^` in the bracket expression to be literal, and the backtick is written literally (no `\x60` escape in ERE):
  `` grep -rnE '(^|[^][:alnum:]_/&#`])#([0-9]{1,4}|[0-9A-Fa-f]{6})\b' pages/ journals/ ``
  — single-quote the pattern: the literal backtick inside it would start command substitution in a double-quoted shell string.)
  Hits already inside backticks, `{{ }}`, or fenced code blocks are false positives (Logseq won't linkify code/macro/fenced content) — mask those before counting.
- **remediation:** `#44` → `` `#44` ``, `#0066CC` → `` `#0066CC` ``. Punctuation-adjacent hits are in scope — `(#1)` → `` (`#1`) ``, `#2–#5` → `` `#2`–`#5` ``. **Never touch `#[[Page Name]]`** (valid tag-link) or `#` already inside backticks/`{{ }}`/fenced blocks. Mask inline-code spans (`` `…` ``), macro spans (`{{…}}`), fenced code blocks (``` … ```), and `#[[…]]` first, transform on the remainder, then unmask.

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

## `jira-markup`
- **severity:** breaks-render
- **enforced-at:** compose, scan
- **auto-fixable:** report
- **detection:** Jira wiki markup outside fenced code blocks. Mask fenced blocks (``` … ```) first — a hit *inside* a fence is a false positive (that is exactly where Jira markup belongs). Then:
  `grep -rnE "(^|[[:space:]])h[1-6]\.[[:space:]]|\{code(:[a-z]+)?\}|\{noformat\}|\[~[A-Za-z0-9._@-]+\]" pages/ journals/`
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

## `missing-digest`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:** a project or task page carrying no digest, **or one whose `## Digest` section has no `Map:` bullet** — the Map is a required slot (`skills/_shared/digest.md`), so a digest missing it is a missing digest, not a shorter one. Excludes session-archive pages and the singletons.
  ```
  for f in pages/Projects___*.md pages/Tasks___*.md; do
    [ -e "$f" ] || continue    # unexpanded glob on a graph with no task pages
    case "$f" in *___SessionArchive.md) continue;; esac
    grep -q "^type:: session-archive" "$f" && continue
    case "$f" in pages/Projects___*.md) grep -q "^type:: project$" "$f" || continue;; esac   # excludes type:: task-index / project-note / etc. — matches the glob but isn't a project
    ok=1
    awk '/^[[:space:]]*-/{exit} 1' "$f" | grep -q "^digest-updated:: " || ok=0
    grep -qE "^(- )?## Digest" "$f" || ok=0
    if [ "$ok" -eq 1 ]; then
      awk '/^(- )?## Digest/{f=1;next} f&&/^(- )?## /{exit} f' "$f" | grep -q "Map:" || ok=0
    fi
    [ "$ok" -eq 1 ] || echo "$(wc -c < "$f") $f missing digest"
  done | sort -rn
  ```
- **remediation:** report each page with its byte size, largest first (biggest pages pay back a digest soonest). Offer the rebuild-from-source procedure in `skills/_shared/digest.md`. **Report-tier**: building a digest is a judgment call with real token cost — never auto-spent. For a whole-graph pass use brain-doctor's guided digest backfill.

## `stale-digest`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:** `digest-updated::` more than 30 days behind `last-updated::` on the same page.
  ```
  for f in pages/Projects___*.md pages/Tasks___*.md; do
    [ -e "$f" ] || continue    # unexpanded glob on a graph with no task pages
    case "$f" in *___SessionArchive.md) continue;; esac
    grep -q "^type:: session-archive" "$f" && continue
    case "$f" in pages/Projects___*.md) grep -q "^type:: project$" "$f" || continue;; esac   # excludes type:: task-index / project-note / etc. — matches the glob but isn't a project
    d=$(grep -m1 "^digest-updated:: " "$f" | awk '{print $2}')
    l=$(grep -m1 "^last-updated:: " "$f" | awk '{print $2}')
    [ -n "$d" ] && [ -n "$l" ] || continue
    ds=$(date -d "$d" +%s 2>/dev/null) || continue
    ls=$(date -d "$l" +%s 2>/dev/null) || continue
    [ "$ls" -gt "$ds" ] || continue   # digest newer than page is not stale
    [ $(( (ls - ds) / 86400 )) -gt 30 ] && echo "$f digest $d vs page $l"
  done
  ```
  (`date -d` is GNU — available in Git Bash and on Linux. On macOS/BSD use `date -j -f %Y-%m-%d "$d" +%s`. If neither is available, compare the `yyyy-MM-dd` strings lexicographically for ordering and report the gap in months rather than days.)
- **remediation:** report both dates and the gap; suggest rebuild-from-source. Never rebuild without confirmation — a rebuild reads real content and costs real tokens.

## `stale-map`
- **severity:** data-quality
- **enforced-at:** scan
- **auto-fixable:** report
- **detection:** pure arithmetic — recompute the page's **real** section sizes (the same enumerate-and-measure approach as `skills/_shared/digest.md`'s derivation shell, since F2 the Map's field list is derived per page, not fixed), parse **whatever labels the page's own `Map:` bullet actually claims** — however many there are, whatever they're called — and diff each claimed figure against the measured size of the section with that name, keyed by name rather than by a fixed position. A claimed label that matches no real section on the page is its own finding: the Map is describing something that isn't there.

  **Parsing keys off the reserved ` | ` separator (`skills/_shared/digest.md` "Format"), not off "the first space before a digit."** The earlier parser split a clause on the first space-then-digit, which breaks the instant a label contains its own digits — and real task-page headings do, constantly: `'2026-04-23 — Step 2 isolated, real root cause found'` and `'2026-04-23 — Step 2 patch VALIDATED on PROD'` both cut down to the label `'2026-04-23 — Step'`, a false "no such section" finding on the first and a silent same-key collision with the second — whose byte diff then never ran, because the mis-parse `continue`d past it. Splitting on the reserved token instead of guessing where prose ends is what makes the split unambiguous regardless of what a heading contains.

  **A label may be truncated for display (`skills/_shared/digest.md`'s 40-character cap, `…` marker).** Resolve it by **exact match** when it carries no `…`; when it does, treat the text before `…` as a **prefix** and find the one real heading whose own first N characters equal it. Exactly one match → resolved, diff proceeds. Zero matches → "no such section." **More than one match → its own finding** ("ambiguous — ").

  **A duplicate label — two clauses parsing to the identical string — is its own finding, not a collision to key through.** Track every label already seen in this Map; the second occurrence is reported and **neither** of the pair is diffed, because the key no longer identifies one section.

  The tolerance is derived from the **unit the Map claims**, not a percentage of the measured size — and it is **one-sided for KB**, not a symmetric ± band. `digest.md` mandates truncation (never round-to-nearest), so a claim of `N KB` asserts the section measures **in `[N·1024, N·1024 + 1023]` bytes** — check `0 <= measured − N·1024 <= 1023`, not `|N·1024 − measured| <= 1024`. The old symmetric form silently accepted an entire adjacent KB tier on the low side: a claim of `87 KB` against a true 88,100 B section (which truncates to `86 KB`, one tier down) drifts only 988 B from `87·1024`, under the old 1024 B band — a wrong claim, undetected. The one-sided form catches it (the measured byte count falls *below* the claimed floor, which a correct truncation never does) while still passing a claim of `87 KB` against 89,200 B (`89200 − 89088 = 112`, inside `[0, 1023]`). A figure stated in bytes carries no rounding step and keeps the existing symmetric **64 B** tier — enough to absorb the `page` self-reference noise noted below, far below any real drift.

  **A claimed section now measuring under 1 KB is flagged regardless of whether its figure still diffs correctly.** `digest.md`'s 1 KB inclusion floor means such a section should already have been dropped from the Map (Remap/Refresh) — a Map still naming it, even at an arithmetically-accurate `200 B`, means that step was skipped.

  The `page` figure used to be a special case beyond ordinary rounding: `brain-save` step 9 measured the page and *then* edited the Map bullet, so the just-written claim went stale by the edit's own length delta the instant it landed — 32 B on a fresh project's first save (sub-1 KB, absorbed by the 64 B byte tier), but on a large page the same self-reference can straddle a KB boundary and drift past even the 1024 B KB tier: measured live, a 106 KB pre-write claim against a 109,786 B post-write total drifted 1,242 B — a correctly-computed Map, false-flagged as stale by write order. That is now fixed at the source, not by tolerance: every Map-writing flow re-measures the page *after* writing and corrects `page` if it changed (`skills/_shared/digest.md`'s "second pass" step; `skills/brain-save/SKILL.md` step 9). With that in place, `page`'s residual drift is like any other figure's — the tolerances above cover genuine rounding error only, and widening them again would just hide a bigger version of the same bug on the next boundary crossing.

  The entry count (`(N entries)` on `Session Log`) and decision count (`(N)` on `Decisions`) have no rounding step at all — a claimed count that doesn't exactly equal the measured count is stale, full stop — while still honoring the omit-when-zero-but-nonempty rule from `digest.md`: a Map that correctly omits a count is not compared. The count itself is scoped with the same widened pattern `digest.md` uses — `grep -cE '^[[:space:]]*- (#{2,6} +)?\[?\[?[0-9]{4}-[0-9]{2}-[0-9]{2}'`, matching a `### `-style dated sub-heading as well as a plain dash-bullet — so this check agrees with what the Map was built from, rather than re-litigating the count with the narrower pattern the Map has already moved past. The reconciling residual (`+N smaller sections, X KB`) is recognized by its `+…smaller sections` prefix and skipped like `Archive` — it names no single section to diff. Scope is identical to the other three digest rules: skip `___SessionArchive.md` and `type:: session-archive`.
  ```
  for f in pages/Projects___*.md pages/Tasks___*.md; do
    [ -e "$f" ] || continue    # unexpanded glob on a graph with no task pages
    case "$f" in *___SessionArchive.md) continue;; esac
    grep -q "^type:: session-archive" "$f" && continue
    case "$f" in pages/Projects___*.md) grep -q "^type:: project$" "$f" || continue;; esac   # excludes type:: task-index / project-note / etc. — matches the glob but isn't a project
    grep -qE "^(- )?## Digest" "$f" || continue
    map=$(awk '/^(- )?## Digest/{f=1;next} f&&/^(- )?## /{exit} f' "$f" | grep -m1 "Map:")
    [ -n "$map" ] || continue

    total=$(wc -c < "$f")
    totallines=$(awk 'END{print NR}' "$f")   # not wc -l — see digest.md: no trailing newline

    # Real section map (excluding Digest itself), used to measure whatever the Map claims
    grep -nE '^(- )?## ' "$f" | grep -v '## Digest$' > /tmp/sm_secmap.txt
    nsecs=$(wc -l < /tmp/sm_secmap.txt)

    measure_section() {   # $1 = exact real heading text (after "## ") -> section body on stdout
      i=1
      while [ "$i" -le "$nsecs" ]; do
        line=$(sed -n "${i}p" /tmp/sm_secmap.txt)
        lineno=$(echo "$line" | cut -d: -f1)
        heading=$(echo "$line" | sed -E 's/^[0-9]+:(- )?## //')
        if [ "$heading" = "$1" ]; then
          next=$((i+1))
          if [ "$next" -le "$nsecs" ]; then
            endline=$(( $(sed -n "${next}p" /tmp/sm_secmap.txt | cut -d: -f1) - 1 ))
          else
            endline=$totallines
          fi
          sed -n "$((lineno+1)),${endline}p" "$f"
          return 0
        fi
        i=$((i+1))
      done
      return 1
    }

    # Resolve a claimed (possibly truncated) label to exactly one real heading.
    # Prints the real heading on success. Return: 0 resolved, 1 no match, 2 ambiguous.
    find_section() {
      claim="$1"
      case "$claim" in
        *…)
          prefix="${claim%…}"
          plen=$(printf '%s' "$prefix" | wc -m)
          matches=0; match_heading=""
          i=1
          while [ "$i" -le "$nsecs" ]; do
            line=$(sed -n "${i}p" /tmp/sm_secmap.txt)
            heading=$(echo "$line" | sed -E 's/^[0-9]+:(- )?## //')
            head_prefix=$(printf '%s' "$heading" | cut -c1-"$plen")
            [ "$head_prefix" = "$prefix" ] && { matches=$((matches+1)); match_heading="$heading"; }
            i=$((i+1))
          done
          [ "$matches" -eq 1 ] && { echo "$match_heading"; return 0; }
          [ "$matches" -eq 0 ] && return 1
          return 2
          ;;
        *)
          measure_section "$claim" >/dev/null && { echo "$claim"; return 0; }
          return 1
          ;;
      esac
    }

    # Split "Map: A | x KB (n) · B | y KB · +N smaller sections, Z KB · page | z KB" on " · "
    labels_seen=""
    echo "$map" | sed 's/.*Map: //' | sed 's/ · /\n/g' | while IFS= read -r clause; do
      case "$clause" in
        "Archive | [["*) continue ;;                  # pointer clause — recognized by its value starting `[[` (digest.md's own rule), never by the label alone. A real section literally named "## Archive" has a byte-figure value instead ("Archive | 3 KB") and does NOT match this pattern, so it falls through and is diffed normally.
        "+"*"smaller sections"*) continue ;;           # reconciling residual, not a section name
      esac

      # Reserved-separator split: label is everything before the LAST " | " —
      # robust even in the (rare) case a label itself contains " | ".
      label=$(printf '%s' "$clause" | sed -E 's/ \| [^|]*$//')
      rest=$(printf '%s' "$clause" | sed -E 's/^.* \| //')

      case " ${labels_seen} " in
        *" ${label} "*) echo "$f: Map claims duplicate label '$label' — ambiguous, not diffed"; continue ;;
      esac
      labels_seen="${labels_seen} ${label}"

      figure=$(echo "$rest" | grep -oE '^[0-9]+(\.[0-9]+)? ?(KB|B)')
      [ -n "$figure" ] || continue
      v=$(echo "$figure" | grep -oE '[0-9]+(\.[0-9]+)?')
      isKB=0
      case "$figure" in
        *KB) cb=$(awk -v v="$v" 'BEGIN{printf "%d", v*1024}'); isKB=1 ;;
        *)   cb=$(awk -v v="$v" 'BEGIN{printf "%d", v}');      tol=64 ;;
      esac

      if [ "$label" = "page" ]; then
        m=$total; resolved="page"
      else
        resolved=$(find_section "$label"); rc=$?
        if [ "$rc" -eq 1 ]; then
          echo "$f: Map claims '$label' but no such section exists on the page"
          continue
        elif [ "$rc" -eq 2 ]; then
          echo "$f: Map claims '$label' but it matches more than one section — ambiguous"
          continue
        fi
        m=$(measure_section "$resolved" | wc -c)
      fi

      # One-sided KB tolerance (truncation-only): 0 <= measured - claimed_floor <= 1023.
      # Byte tier stays symmetric (no rounding direction to respect).
      if [ "$isKB" -eq 1 ]; then
        d=$((m - cb))
        { [ "$d" -lt 0 ] || [ "$d" -gt 1023 ]; } && echo "$f: $label claims $figure, measured ${m}B"
      else
        diff=$(( cb > m ? cb - m : m - cb ))
        [ "$diff" -gt "$tol" ] && echo "$f: $label claims $figure, measured ${m}B"
      fi

      # 1 KB inclusion floor: a claimed (non-page) section now under 1024 B should have been dropped
      [ "$label" != "page" ] && [ "$m" -lt 1024 ] && \
        echo "$f: $label claims $figure but now measures ${m}B, below the 1 KB inclusion floor — should have been dropped"

      # Exact count check — only fires when the clause actually carries a count
      case "$clause" in
        *"entries)"*)
          cc=$(echo "$clause" | grep -oE '\([0-9]+ entries\)' | grep -oE '[0-9]+')
          mc=$(measure_section "$resolved" | grep -cE '^[[:space:]]*- (#{2,6} +)?\[?\[?[0-9]{4}-[0-9]{2}-[0-9]{2}')
          [ -n "$cc" ] && [ "$cc" != "$mc" ] && echo "$f: $label claims ($cc entries), measured $mc"
          ;;
        *"("*")"*)
          cc=$(echo "$clause" | grep -oE '\([0-9]+\)' | grep -oE '[0-9]+')
          if [ -n "$cc" ]; then
            mc=$(measure_section "$resolved" | grep -cE '^[[:space:]]*- (#{2,6} +)?\[?\[?[0-9]{4}-[0-9]{2}-[0-9]{2}')
            [ "$cc" != "$mc" ] && echo "$f: $label claims ($cc), measured $mc"
          fi
          ;;
      esac
    done
  done
  ```
  This is the rule that catches what the other three digest rules cannot: `digest-updated::` and `## Digest`'s mere presence say nothing about whether the *bytes it claims* — or the *entry count* it claims, the figure `brain-load` quotes most prominently ("47 sessions of log not read") — still match the page, and F2 means that check must now hold for however many sections a real page's Map actually lists, not just a fixed four. Rotation is the primary offender (see `skills/brain-save/references/rotation.md`) — it moves tens of KB out of `## Session Log` and, absent the digest-remap step added there, leaves the Map quoting a page that no longer exists.
- **remediation:** report each mismatched figure (claimed vs. measured), report any claimed label that matches no real section (or matches more than one), report any duplicate label, report any claimed section now under the 1 KB inclusion floor, and suggest a rebuild per `skills/_shared/digest.md`. Report-tier, like the other digest rules — a rebuild reads real content and costs real tokens, never spent without confirmation.

## `oversized-digest`
- **severity:** data-quality
- **enforced-at:** compose, scan
- **auto-fixable:** safe-only
- **detection:** the `## Digest` section exceeds 800 bytes, or any digest property value exceeds 120 **bytes**.
  ```
  for f in pages/Projects___*.md pages/Tasks___*.md; do
    [ -e "$f" ] || continue    # unexpanded glob on a graph with no task pages
    case "$f" in *___SessionArchive.md) continue;; esac
    grep -q "^type:: session-archive" "$f" && continue
    case "$f" in pages/Projects___*.md) grep -q "^type:: project$" "$f" || continue;; esac   # excludes type:: task-index / project-note / etc. — matches the glob but isn't a project
    b=$(awk '/^(- )?## Digest/{f=1;next} f&&/^(- )?## /{exit} f' "$f" | wc -c)
    [ "$b" -gt 800 ] && echo "$f digest ${b}B > 800B"
    LC_ALL=C grep -nE "^(focus|next|open):: .{121,}" "$f" | sed "s|^|$f |"
  done
  ```
  **`LC_ALL=C` on the property check is load-bearing, not decoration.** `.` in a regex matches one *character*, and under a UTF-8 locale (`LC_ALL=en_US.UTF-8` etc.) a multi-byte character (`—`, `·` — both appear in this file's own digest examples) counts as one `.`, so a value that is genuinely 121 **bytes** but only 120 **characters** silently passes `.{121,}` and the cap is missed. The section-size check above already uses `wc -c`, which is byte-exact regardless of locale — forcing `LC_ALL=C` makes the property check agree with it on the same machine instead of drifting apart under whatever locale the shell happens to have.
- **remediation:** the safe subset is **compose-time only** — `brain-save` recompresses its own composed digest before writing it: drop the free slot first, then shorten Binding and Hazard; **never drop the Map**. At **scan** time this rule is **report-only**: trimming content already on disk is never safe to automate, because the excess may be the only place something is recorded. Same scoping discipline as `malformed-property`.

## Post-write verify (scoped)

For skills that write graph files (brain-save; reusable by brain-init): after **all** writes in the operation are done, verify what actually landed on disk. This is the mechanical safety net behind the compose-time self-check — instructions alone demonstrably miss things (see the v0.9.0 design spec).

1. Collect the list of files written in this operation (project/task page, journal, `Index.md`, `Meta.md`, …).
2. In **one** Bash call, run the detections for `code-in-braces`, `bare-hash-tag`, `unnamespaced-link`, and `file-link` with `pages/ journals/` replaced by that file list, plus per-file backtick parity:
   ```
   F="pages/Projects___X.md journals/2026_07_07.md"   # the actual list
   grep -nE "\{\{[^}]*\}\}" $F
   grep -nP "(?<![\w/&\x60#\]])#([0-9]{1,4}|[0-9A-Fa-f]{6})\b" $F
   grep -nE "\[\[(CRMGM|GLOPRICE)-[0-9]+\]\]" $F
   grep -nE "\[\[file:///" $F
   for f in $F; do c=$(grep -o '`' "$f" | wc -l); [ $((c%2)) -ne 0 ] && echo "ODD backticks: $f"; done; true
   ```
   (Apply each rule's masking notes when judging hits — e.g. a `#N` inside backticks or a `{{x}}` inside a fenced block is a false positive. The `grep -nP` line needs PCRE support — no `-P` on this host → use the ERE fallback documented in `bare-hash-tag`. If an odd backtick count traces into a fenced code block (e.g. a verbatim Jira draft), leave the fence content untouched — verbatim fenced content is exempt; investigate the lines this save wrote instead.)
3. Any real hit → apply that rule's remediation with a surgical Edit → re-run that detection on that file; expect zero.
4. Report in the skill's final confirmation: "post-write check: clean" or "post-write check fixed N issues". Hits on lines this save wrote → fix silently, it's the skill's own output. Hits clearly on pre-existing lines this save didn't touch → still safe-tier fixable, but call them out explicitly in the confirmation (e.g. "also fixed a pre-existing `#12` in Index.md") so the user knows content beyond this session's writes was touched — or report-and-defer to brain-doctor if the fix would be invasive. No user prompt needed for the silent case — the skill is correcting its own just-written output, which the compose invariants already commit it to.

## After repair — verify

- Re-run each detection; expect zero (minus intentional forward-references).
- Per-file backtick parity: every file should have an **even** number of `` ` `` characters (odd = a broken inline-code span introduced by the fix).
```
for f in pages/*.md journals/*.md; do c=$(grep -o '`' "$f" | wc -l); [ $((c%2)) -ne 0 ] && echo "ODD: $f"; done; true
```
