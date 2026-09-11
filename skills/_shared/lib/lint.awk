# lint.awk — Logseq-faithful format rules (spec §4) over graph-relative files. Run from the graph root.
#   -v listfile=FILE   files to lint, one per line
#   -v pagesfile=FILE  existing page names, lowercased ("projects/x")
#   -v keysfile=FILE   "count key" lines: property-key usage over the whole graph
#   -v addedfile=FILE  check mode: only these line numbers are reported; other findings are counted
#   -v nobase=1        check mode without a baseline: report everything, suffixed, never exit 1

function blank(n,   s) { s = ""; while (n-- > 0) s = s " "; return s }

# Blank every match of dynamic regex re, keeping column positions.
function mask_re(s, re,   out) {
  out = ""
  while (match(s, re)) { out = out substr(s, 1, RSTART - 1) blank(RLENGTH); s = substr(s, RSTART + RLENGTH) }
  return out s
}

# Blank inline code: a run of k backticks through the next run of exactly k backticks.
function mask_code(s,   out, i, j, k, r, n, found) {
  out = ""; i = 1; n = length(s)
  while (i <= n) {
    if (substr(s, i, 1) != "`") { out = out substr(s, i, 1); i++; continue }
    k = 0; while (i + k <= n && substr(s, i + k, 1) == "`") k++
    j = i + k; found = 0
    while (j <= n) {
      if (substr(s, j, 1) == "`") {
        r = 0; while (j + r <= n && substr(s, j + r, 1) == "`") r++
        if (r == k) { found = 1; break }
        j += r
      } else j++
    }
    if (found) { out = out blank(j + k - i); i = j + k }
    else { out = out substr(s, i, k); i += k }
  }
  return out
}

function emit(i, rule, tier, detail) {
  if (CHECK && !(i in ADDED)) { PRE++; return }
  if (nobase) detail = detail " (no baseline — may be pre-existing)"
  printf "%s:%d\t%s\t%s\t%s\n", CURF, i, rule, tier, detail
  if (tier == "error") NE++; else NW++
}

function lint_file(f,   i, inf, t, m1, m2, j, nx, tok, pv, cls, rest, pos, e, tgt, k) {
  CURF = f
  scan_props()
  inf = 0
  for (i = 1; i <= N; i++) {
    t = cr(L[i])
    if (is_fence_line(t)) { inf = !inf; continue }
    if (inf) continue
    m1 = mask_code(t)

    rest = m1
    while ((pos = index(rest, "{{")) > 0) {
      rest = substr(rest, pos)
      if (substr(rest, 1, 4) != "{{}}" && rest !~ /^\{\{[ \t]*(query|embed|video|renderer|cards|function|namespace|tutorial|cloze|youtube|youtube-timestamp|vimeo|bilibili|tweet|twitter|pdf|contents|zotero-imported-file|zotero-linked-file)([ \t}]|$)/) {
        e = index(rest, "}}")
        emit(i, "code-in-braces", "error", e ? substr(rest, 1, e + 1) : substr(rest, 1, 30))
      }
      rest = substr(rest, 3)
    }

    m2 = mask_re(mask_re(mask_re(mask_re(m1, MDLINK), URLRE), TAGLINK), HEADRE)
    for (j = 1; j <= length(m2); j++) {
      if (substr(m2, j, 1) != "#") continue
      nx = substr(m2, j + 1, 1)
      if (nx == "" || index(" \t#[]`,\"*.;:!?'", nx)) continue
      tok = substr(m2, j + 1); sub(/[ \t].*$/, "", tok)
      pv = (j > 1) ? substr(m2, j - 1, 1) : ""
      if (pv ~ /[A-Za-z0-9]/) cls = "after-word"
      else if (tok ~ /^[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]([^0-9A-Za-z]|$)/ && tok ~ /^[0-9]*[A-Fa-f]/) cls = "hex"
      else if (tok ~ /^[0-9]/) cls = "number"
      else if (tok ~ /^[A-Za-z]/) cls = "word"
      else cls = "punct"
      emit(i, "bare-hash-tag", "error", "#" tok " (" cls ")")
      j += length(tok)
    }

    rest = m1
    while (match(rest, /\[\[[A-Z][A-Z0-9]*-[0-9]+\]\]/)) {
      emit(i, "unnamespaced-link", "error", substr(rest, RSTART, RLENGTH)); rest = substr(rest, RSTART + RLENGTH)
    }

    rest = m1
    while ((pos = index(rest, "[[file:")) > 0) {
      rest = substr(rest, pos); e = index(rest, "]]")
      emit(i, "file-link", "error", e ? substr(rest, 1, e + 1) : rest); rest = substr(rest, 3)
    }

    rest = m1
    while (match(rest, /\[[^]]*\]\([^)]*\)/)) {
      tgt = substr(rest, RSTART, RLENGTH); sub(/^\[[^]]*\]\(/, "", tgt); sub(/\)$/, "", tgt)
      # (( and [[ targets are Logseq's labeled block/page refs, not relative files.
      if (tgt != "" && tgt !~ /^(https?:|ftp:|file:|mailto:|#|\.\.\/assets\/|assets\/|\(\(|\[\[)/) emit(i, "relative-link", "error", tgt)
      rest = substr(rest, RSTART + RLENGTH)
    }

    if (m1 ~ /(^|[ \t])h[1-6]\.[ \t]/ || m1 ~ /\{code(:[a-z]+)?\}/ || m1 ~ /\{noformat\}/ || \
        m1 ~ /\[~[A-Za-z0-9._@-]+\]/ || m1 ~ /^[ \t]*(- )?\|\|/)
      emit(i, "jira-markup", "error", substr(bullet_text(t), 1, 60))

    if (i <= PROP_END && t ~ /^[a-z][a-z0-9-]*: /) {
      k = t; sub(/: .*$/, "", k); emit(i, "malformed-property", "error", k ": → " k "::")
    }

    rest = m1
    while (match(rest, /\[\[(Projects|Tasks)\/[^]]+\]\]/)) {
      tgt = substr(rest, RSTART + 2, RLENGTH - 4)
      if (!(tolower(tgt) in PAGES)) emit(i, "broken-link", "warn", "[[" tgt "]] — no page file")
      rest = substr(rest, RSTART + RLENGTH)
    }

    if (match(t, /^[ \t]*(- )?[A-Za-z0-9_][A-Za-z0-9_.-]*:: /)) {
      k = substr(t, 1, RLENGTH - 3); sub(/^[ \t]*(- )?/, "", k); k = tolower(k)
      if ((k in KEYC) && KEYC[k] == 1 && !(k in KNOWN)) emit(i, "new-property-key", "warn", k ":: used nowhere else in the graph")
    }
  }
}

BEGIN {
  MDLINK = "\\[[^]]*\\]\\([^)]*\\)"
  URLRE = "(https?|ftp|mailto|file):[^] \t)>]*"
  TAGLINK = "#\\[\\[[^]]*\\]\\]"
  HEADRE = "^(- )?#+ "
  # Keys the plugin itself writes are never "new", even when a small graph uses one only once.
  nk = split("type status created last-updated focus next open digest-updated project projects task-id " \
    "jira source tags alias files-modified skills-used related-tickets open-questions next-action " \
    "context alternatives rationale superseded-by supersedes estimate task-folder summary collapsed id", kn, " ")
  for (i = 1; i <= nk; i++) KNOWN[kn[i]] = 1
  if (pagesfile != "") while ((getline ln < pagesfile) > 0) PAGES[ln] = 1
  if (keysfile != "") while ((getline ln < keysfile) > 0) { split(ln, kv, " "); KEYC[kv[2]] = kv[1] + 0 }
  if (addedfile != "") { CHECK = 1; while ((getline ln < addedfile) > 0) ADDED[ln + 0] = 1 }
  nf = 0
  while ((getline f < listfile) > 0) {
    reset()
    while ((getline ln < f) > 0) L[++N] = ln
    close(f)
    lint_file(f); nf++; last = f
  }
  if (CHECK) printf "check %s: %d new (%d error, %d warn), %d pre-existing\n", last, NE + NW, NE, NW, PRE
  else if (nobase) printf "check %s: no baseline — %d finding(s) shown, may be pre-existing\n", last, NE + NW
  exit ((CHECK && NE > 0) ? 1 : 0)
}
