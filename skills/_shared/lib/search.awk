# search.awk — `brain search`. Run from the graph root.
#   -v listfile=FILE -v sec=NAME|"" -v ctx=N|"" -v scope=TEXT ; the term arrives as ENVIRON["BRAIN_TERM"]
#   (not -v, which would rewrite backslashes in a term such as a Windows path).
function sect_of(i,   k) { for (k = NS; k >= 1; k--) if (SL[k] <= i) return k; return 0 }

function find_sec(name,   k, n, hit, p) {
  for (k = 1; k <= NS; k++) if (SH[k] == name) return k
  p = name; sub(/…$/, "", p); n = 0
  for (k = 1; k <= NS; k++) if (index(SH[k], p) == 1) { n++; hit = k }
  return (n == 1) ? hit : 0
}

function flush(f, a, b,   i, bytes, k) {
  bytes = 0
  for (i = a; i <= b; i++) bytes += lbytes(i)
  CTXB += bytes; NWIN++
  if (CTXB > MAXCTX) { OVER = 1; return }
  k = sect_of(a)
  CTXOUT = CTXOUT sprintf("%s:%d-%d [%s]\n", f, a, b, k ? SH[k] : "(top)")
  for (i = a; i <= b; i++) CTXOUT = CTXOUT cr(L[i]) "\n"
}

BEGIN {
  MAXHITS = 20; MAXBYTES = 4096; MAXCTX = 8192
  term = ENVIRON["BRAIN_TERM"]
  tl = tolower(term); M = 0; K = 0; HITBYTES = 0; CTXB = 0; NWIN = 0; OVER = 0; CTXOUT = ""
  while ((getline f < listfile) > 0) {
    reset(); NONL = 0
    while ((getline ln < f) > 0) L[++N] = ln
    close(f)
    scan(); scan_props()
    ks = 0; lo = 1; hi = N
    if (sec != "") {
      ks = find_sec(sec)
      if (!ks) { printf "brain: no unique section \"%s\" in %s\n", sec, f > "/dev/stderr"; exit 2 }
      lo = SL[ks] + 1; hi = SE[ks]
    }
    mark = ""
    if (PROP["type"] == "session-archive" || f ~ /___SessionArchive\.md$/) mark = " (archive)"
    else if (f ~ /^pages\/Tasks___/ && PROP["status"] == "done") mark = " (done task)"
    fh = 0; wa = 0
    for (k = 1; k <= NS; k++) SECN[k] = 0
    for (i = lo; i <= hi; i++) {
      if (!index(tolower(L[i]), tl)) continue
      M++; fh++
      k = sect_of(i); if (k) SECN[k]++
      t = cr(L[i]); sub(/^[ \t]+/, "", t)
      if (length(t) > 200) t = utf8_cut(t, 200) "…"
      HITS[M] = sprintf("%s:%d [%s]%s %s", f, i, k ? SH[k] : "(top)", mark, t)
      HITBYTES += length(HITS[M]) + 1
      if (ctx != "") {
        a = i - ctx; b = i + ctx
        if (a < lo) a = lo
        if (b > hi) b = hi
        if (wa && a <= wb + 1) { if (b > wb) wb = b }
        else { if (wa) flush(f, wa, wb); wa = a; wb = b }
      }
    }
    if (wa) flush(f, wa, wb)
    if (fh) {
      K++
      s = ""
      for (k = 1; k <= NS; k++) if (SECN[k]) s = s (s != "" ? " · " : "") SH[k] " " SECN[k]
      COUNTS[K] = sprintf("%s: %s — %s", f, pl(fh, "hit"), s)
    }
  }
  if (ctx == "" && M <= MAXHITS && HITBYTES <= MAXBYTES) {
    for (i = 1; i <= M; i++) print HITS[i]
    printf "coverage: showed %d of %s in %s (scope: %s)\n", M, pl(M, "hit"), pl(K, "file"), scope
    exit 0
  }
  if (ctx != "" && !OVER) {
    printf "%s", CTXOUT
    printf "coverage: showed %d of %s in %s, %s (scope: %s)\n", M, pl(M, "hit"), pl(NWIN, "window"), hb(CTXB), scope
    exit 0
  }
  for (i = 1; i <= K && i <= 30; i++) print COUNTS[i]
  if (K > 30) printf "+%d more files\n", K - 30
  if (ctx != "")
    printf "coverage: showed 0 of %s — context windows would be %s (cap %s) (scope: %s)\n", pl(M, "hit"), hb(CTXB), hb(MAXCTX), scope
  else
    printf "coverage: showed 0 of %s in %s (scope: %s) — narrow the term or pass --page/--section\n", pl(M, "hit"), pl(K, "file"), scope
  exit 0
}
