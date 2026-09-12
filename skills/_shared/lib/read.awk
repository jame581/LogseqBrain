# read.awk — `brain read` (mode=read) and `brain tail` (mode=tail).
#   -v rel=REL -v nonl=0|1 -v mode=read|tail -v sec=NAME -v max=BYTES -v entries=N
{ L[++N] = $0 }

function find_section(name,   k, hit, n, p, names) {
  n = 0
  for (k = 1; k <= NS; k++) if (SH[k] == name) { n++; hit = k }
  if (n == 1) return hit
  if (n > 1) {
    printf "brain: ## %s appears %d times in %s — malformed page; not guessing which to read\n", name, n, rel > "/dev/stderr"
    exit 2
  }
  p = name; sub(/…$/, "", p)
  n = 0
  for (k = 1; k <= NS; k++) if (index(SH[k], p) == 1) { n++; hit = k }
  if (n == 1) return hit
  n = 0
  for (k = 1; k <= NS; k++) if (tolower(SH[k]) == tolower(p)) { n++; hit = k }
  if (n == 1) return hit
  names = ""
  for (k = 1; k <= NS; k++) names = names (k > 1 ? ", " : "") SH[k]
  printf "brain: no unique section \"%s\" in %s (sections: %s)\n", name, rel, names > "/dev/stderr"
  exit 2
}

END {
  NONL = nonl; scan()
  k = find_section(sec)
  if (mode == "read") {
    if (SB[k] > max + 0) {
      printf "refused: ## %s is %s (cap %s) — use brain tail or brain search --section \"%s\"\n", SH[k], hb(SB[k]), hb(max), SH[k]
      exit 1
    }
    for (i = SL[k]; i <= SE[k]; i++) print cr(L[i])
    printf "coverage: whole ## %s (%s), lines %d-%d of %s\n", SH[k], hb(SB[k]), SL[k], SE[k], rel
    exit 0
  }
  m = 0
  for (i = SL[k] + 1; i <= SE[k]; i++) if (!FENCE[i] && is_dated(L[i])) st[++m] = i
  if (m == 0) {
    b = 0; from = SE[k] + 1
    while (from - 1 > SL[k] && (b + lbytes(from - 1) <= max + 0 || from == SE[k] + 1)) { from--; b += lbytes(from) }
    for (i = from; i <= SE[k]; i++) print cr(L[i])
    printf "coverage: last %s of %s of ## %s (no dated entries; coverage by bytes)\n", hb(b), hb(SB[k]), SH[k]
    exit 0
  }
  n = (entries + 0 < m) ? entries + 0 : m
  if (n < 1) n = 1                      # --entries 0 must not loop or read outside the section
  while (1) {
    b = 0
    for (i = st[m - n + 1]; i <= SE[k]; i++) b += lbytes(i)
    if (b <= max + 0 || n == 1) break
    n--
  }
  for (i = st[m - n + 1]; i <= SE[k]; i++) print cr(L[i])
  printf "coverage: %d of %d entries, %s of %s of ## %s\n", n, m, hb(b), hb(SB[k]), SH[k]
}
