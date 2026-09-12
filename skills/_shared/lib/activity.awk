# activity.awk — today's journal with one "HH:MM text" bullet placed per journey-log.md.
#   -v nonl=0|1 -v new=0|1 ; bullet text in ENVIRON["BRAIN_BULLET"]. new=1 reads /dev/null.
{ L[++N] = $0 }
END {
  bullet = ENVIRON["BRAIN_BULLET"]
  if (new) { printf "- ## Sessions\n- ## Activity\n  - %s\n", bullet; exit 0 }
  NONL = nonl; scan()
  CRS = (N && L[1] ~ /\r$/) ? "\r" : ""
  ka = 0; ks = 0
  for (k = 1; k <= NS; k++) {
    if (SH[k] == "Activity" && !ka) ka = k
    if (SH[k] == "Sessions" && !ks) ks = k
  }
  M = 0
  if (ka) {
    p = SL[ka]; ind = ""
    for (i = SL[ka] + 1; i <= SE[ka]; i++) {
      if (cr(L[i]) != "") p = i
      if (ind == "" && !FENCE[i] && match(L[i], /^[ \t]+- /)) ind = substr(L[i], 1, RLENGTH - 2)
    }
    if (ind == "") ind = "  "
    for (i = 1; i <= N; i++) { O[++M] = L[i]; if (i == p) O[++M] = ind "- " bullet CRS }
  } else if (N == 0) {
    O[++M] = "- ## Activity"; O[++M] = "  - " bullet
  } else {
    p = ks ? SE[ks] : N
    for (i = 1; i <= N; i++) {
      O[++M] = L[i]
      if (i == p) { O[++M] = "- ## Activity" CRS; O[++M] = "  - " bullet CRS }
    }
  }
  for (i = 1; i <= M; i++) { printf "%s", O[i]; if (i < M || !NONL) printf "\n" }
}
