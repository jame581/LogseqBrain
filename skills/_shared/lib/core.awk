# core.awk — shared helpers for every brain awk program.
# Loaded first:  awk -f core.awk -f <prog>.awk -v nonl=0|1 ... FILE
# LC_ALL=C is set by the dispatcher, so length()/substr() count BYTES.
# POSIX awk only: no gensub, no 3-arg match, no strftime/mktime, no {n,m} intervals.

function reset(   k) {
  for (k in L) delete L[k]
  for (k in FENCE) delete FENCE[k]
  for (k in PROP) delete PROP[k]
  for (k in PROPLINE) delete PROPLINE[k]
  N = 0; NS = 0; TOTAL = 0; PROP_END = 0
}

function cr(s) { sub(/\r$/, "", s); return s }

# Bytes of line i on disk: its content plus the newline, except a final line with none.
function lbytes(i) { return length(L[i]) + ((i == N && NONL) ? 0 : 1) }

function is_fence_line(s) { return cr(s) ~ /^[ \t]*(- )?```/ }

# "## X" or "- ## X" at column 0 → "X"; anything else → "".
function heading_text(s,   t) {
  t = cr(s)
  if (t !~ /^(- )?## [^ ]/) return ""
  sub(/^(- )?## /, "", t); sub(/[ \t]+$/, "", t)
  return t
}

# The digest.md dated-headline shape, widened to "### " sub-headings, without {n,m} intervals.
function is_dated(s) {
  return cr(s) ~ /^[ \t]*- (###+ +)?\[?\[?[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/
}

function indent_w(s,   j, c, w) {
  w = 0
  for (j = 1; j <= length(s); j++) {
    c = substr(s, j, 1)
    if (c == " ") w++
    else if (c == "\t") w += 2
    else break
  }
  return w
}

function bullet_text(s,   t) { t = cr(s); sub(/^[ \t]*- /, "", t); return t }

function excluded_child(x) {
  return x ~ /^[a-z][a-z0-9-]*:: / || x ~ /^_.*_[ \t]*$/ || (index(x, "[[") && index(x, "SessionArchive]]"))
}

function scan(   i, inf, h, k, t, ind, minind) {
  TOTAL = 0; NS = 0; inf = 0
  for (i = 1; i <= N; i++) {
    TOTAL += lbytes(i)
    if (is_fence_line(L[i])) { FENCE[i] = 1; inf = !inf; continue }
    FENCE[i] = inf
    if (inf) continue
    h = heading_text(L[i])
    if (h != "") { NS++; SH[NS] = h; SL[NS] = i }
  }
  for (k = 1; k <= NS; k++) {
    SE[k] = (k < NS) ? SL[k + 1] - 1 : N
    SB[k] = 0; SD[k] = 0; SC[k] = 0; minind = -1
    for (i = SL[k] + 1; i <= SE[k]; i++) {
      SB[k] += lbytes(i)
      if (FENCE[i]) continue
      t = cr(L[i])
      if (is_dated(t)) SD[k]++
      if (t ~ /^[ \t]*- /) { ind = indent_w(t); if (minind < 0 || ind < minind) minind = ind }
    }
    for (i = SL[k] + 1; i <= SE[k]; i++) {
      if (FENCE[i]) continue
      t = cr(L[i])
      if (t ~ /^[ \t]*- / && indent_w(t) == minind && !excluded_child(bullet_text(t))) SC[k]++
    }
  }
}

# Page-top property block: bare "key:: value" lines before the first bullet or heading.
function scan_props(   i, t, k) {
  for (i = 1; i <= N; i++) {
    t = cr(L[i])
    if (t ~ /^[ \t]*- / || heading_text(t) != "") break
  }
  PROP_END = i - 1
  for (i = 1; i <= PROP_END; i++) {
    t = cr(L[i])
    if (match(t, /^[A-Za-z0-9_][A-Za-z0-9_.-]*:: /)) {
      k = substr(t, 1, RLENGTH - 3)
      PROP[k] = substr(t, RLENGTH + 1); PROPLINE[k] = i
    }
  }
}

function fig(b) { return (b >= 1024) ? int(b / 1024) " KB" : b " B" }

# Human-readable size for coverage lines (not Map figures): "N B" under 1 KiB, else "X.Y KB".
function hb(b) { return (b < 1024) ? b " B" : sprintf("%.1f KB", b / 1024) }

function dd(n) { return n " day" ((n == 1 || n == -1) ? "" : "s") }

function pl(n, w) { return n " " w ((n == 1) ? "" : "s") }

# Cut s to at most n bytes without splitting a UTF-8 sequence.
function utf8_cut(s, n,   t, j, c, need) {
  if (length(s) <= n) return s
  t = substr(s, 1, n); j = n
  while (j > 0 && substr(t, j, 1) ~ /^[\200-\277]$/) j--
  if (j == 0) return t
  c = substr(t, j, 1)
  need = 1
  if (c ~ /^[\300-\337]$/) need = 2
  else if (c ~ /^[\340-\357]$/) need = 3
  else if (c ~ /^[\360-\367]$/) need = 4
  if (n - j + 1 < need) t = substr(t, 1, j - 1)
  return t
}

# Map label: the heading, or its n-byte cut plus an ellipsis when it is longer.
function label(h, n) { return (length(h) <= n) ? h : utf8_cut(h, n) "…" }

# yyyy-MM-dd → day number (proleptic Gregorian, March-based), -1 if malformed.
# (The local is "dy", not "dd": a parameter may not shadow the function dd() in POSIX awk.)
function days(d,   y, m, dy) {
  if (d !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return -1
  y = substr(d, 1, 4) + 0; m = substr(d, 6, 2) + 0; dy = substr(d, 9, 2) + 0
  if (m <= 2) { y--; m += 12 }
  return 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + dy
}

# skills/_shared/staleness.md levels. TODAY must be set (-v today=...).
function staleness(lu, st, typ, is_task,   n) {
  if (typ == "session-archive") return "exempt"
  if (is_task && (st == "done" || st == "")) return "exempt"   # done, or legacy with no status::
  if (days(lu) < 0) return "aging (no valid last-updated)"
  n = days(today) - days(lu)
  if (n <= 7) return "fresh (" dd(n) ")"
  if (n <= 14) return "aging (" dd(n) ")"
  if (n <= 29) return "stale (" dd(n) ")"
  return ((st == "active") ? "abandoned (" : "stale (") dd(n) ")"
}

# digest.md scope. Call after scan_props().
function bearing(rel) {
  if (rel ~ /___SessionArchive\.md$/ || PROP["type"] == "session-archive") return 0
  if (rel ~ /^pages\/Tasks___/) return 1
  if (rel ~ /^pages\/Projects___/ && PROP["type"] == "project") return 1
  return 0
}
