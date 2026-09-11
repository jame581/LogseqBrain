# journal.awk — `brain journal`: one page's mentions in one journal, oldest dropped until <= target.
#   -v rel=REL -v nonl=0|1 -v name=Projects/X -v target=2048
{ L[++N] = $0 }
END {
  NONL = nonl; scan()
  key = "[[" tolower(name) "]]"; m = 0
  for (i = 1; i <= N; i++) {
    if (FENCE[i]) continue
    t = cr(L[i])
    if (t !~ /^[ \t]*- \[\[/ || index(tolower(bullet_text(t)), key) != 1) continue
    ind = indent_w(t); e = i
    for (j = i + 1; j <= N; j++) { u = cr(L[j]); if (u != "" && indent_w(u) <= ind) break; e = j }
    m++; BS[m] = i; BE[m] = e; BB[m] = 0
    for (j = i; j <= e; j++) BB[m] += lbytes(j)
    i = e
  }
  if (m == 0) { printf "coverage: no mention of [[%s]] in %s (%s)\n", name, rel, hb(TOTAL); exit 0 }
  first = 1; tot = 0
  for (k = 1; k <= m; k++) tot += BB[k]
  while (tot > target + 0 && first < m) { tot -= BB[first]; first++ }
  for (k = first; k <= m; k++) for (j = BS[k]; j <= BE[k]; j++) print cr(L[j])
  printf "coverage: %d of %s, %s of %s journal (%s)\n", m - first + 1, pl(m, "mention"), hb(tot), hb(TOTAL), rel
}
