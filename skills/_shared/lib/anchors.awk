# anchors.awk — save-begin's Edit anchors. Page name in ENVIRON["BRAIN_NAME"].
#   -v mode=index    on pages/Index.md: the page's one-liner under ## Projects
#   -v mode=sessions on today's journal: where ## Sessions ends (the rule activity.awk appends by)
{ L[++N] = $0 }
END {
  NONL = nonl; scan()
  if (mode == "index") {
    index_lines(ENVIRON["BRAIN_NAME"])
    if (IDXN == 0) print "index: missing"
    else if (IDXN == 1) printf "index: %d %s\n", IDX[1], cr(L[IDX[1]])
    else {
      s = IDX[1]; for (j = 2; j <= IDXN; j++) s = s "," IDX[j]
      printf "index: ambiguous (%d lines: %s)\n", IDXN, s
    }
    exit 0
  }
  for (k = 1; k <= NS; k++) if (SH[k] == "Sessions") break
  if (k > NS) { print "sessions: absent"; exit 0 }
  p = SL[k]
  for (i = SL[k] + 1; i <= SE[k]; i++) if (cr(L[i]) != "") p = i
  if (p == SL[k]) printf "sessions: heading at %d, empty\n", SL[k]
  else printf "sessions: heading at %d, last line at %d\n", SL[k], p
}
