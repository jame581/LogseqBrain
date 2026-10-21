# activity.awk — today's journal with one bullet placed under ## Activity (journey-log.md) or ## Sessions.
#   -v section=Activity|Sessions (default Activity) -v nonl=0|1 -v new=0|1 ; bullet text in
#   ENVIRON["BRAIN_BULLET"]. new=1 reads /dev/null.
#   Activity: appended under ## Activity; with none, the heading goes after ## Sessions, else at the end.
#   Sessions: appended under ## Sessions; with none, the heading goes before ## Activity, else at the end.
#   An identical Sessions bullet already there leaves the file unchanged (a rerun writes nothing).
{ L[++N] = $0 }
END {
  if (section == "") section = "Activity"
  bullet = ENVIRON["BRAIN_BULLET"]
  if (new) {
    if (section == "Sessions") printf "- ## Sessions\n  - %s\n", bullet
    else printf "- ## Sessions\n- ## Activity\n  - %s\n", bullet
    exit 0
  }
  NONL = nonl; scan()
  CRS = (N && L[1] ~ /\r$/) ? "\r" : ""
  ka = 0; ks = 0
  for (k = 1; k <= NS; k++) {
    if (SH[k] == "Activity" && !ka) ka = k
    if (SH[k] == "Sessions" && !ks) ks = k
  }
  kt = (section == "Sessions") ? ks : ka
  M = 0
  if (kt) {
    p = SL[kt]; ind = ""
    for (i = SL[kt] + 1; i <= SE[kt]; i++) {
      if (cr(L[i]) != "") p = i
      if (section == "Sessions" && !FENCE[i] && bullet_text(L[i]) == bullet && cr(L[i]) ~ /^[ \t]*- /) same = 1
      if (ind == "" && !FENCE[i] && match(L[i], /^[ \t]+- /)) ind = substr(L[i], 1, RLENGTH - 2)
    }
    if (same) { for (i = 1; i <= N; i++) { printf "%s", L[i]; if (i < N || !NONL) printf "\n" }; exit 0 }
    if (ind == "") ind = "  "
    for (i = 1; i <= N; i++) { O[++M] = L[i]; if (i == p) O[++M] = ind "- " bullet CRS }
  } else if (N == 0) {
    O[++M] = "- ## " section; O[++M] = "  - " bullet
  } else if (section == "Sessions" && ka) {
    for (i = 1; i <= N; i++) {
      if (i == SL[ka]) { O[++M] = "- ## Sessions" CRS; O[++M] = "  - " bullet CRS }
      O[++M] = L[i]
    }
  } else {
    p = (section == "Activity" && ks) ? SE[ks] : N
    for (i = 1; i <= N; i++) {
      O[++M] = L[i]
      if (i == p) { O[++M] = "- ## " section CRS; O[++M] = "  - " bullet CRS }
    }
  }
  for (i = 1; i <= M; i++) { printf "%s", O[i]; if (i < M || !NONL) printf "\n" }
}
