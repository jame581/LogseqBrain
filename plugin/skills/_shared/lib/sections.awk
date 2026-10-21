# sections.awk — `brain sections`: one row per "## " section.  -v rel=REL -v nonl=0|1
{ L[++N] = $0 }
END {
  NONL = nonl; scan()
  printf "# %s · %d B (%s) · %d sections\n", rel, TOTAL, fig(TOTAL), NS
  print "line\tend\tbytes\tentries\theading"
  for (k = 1; k <= NS; k++)
    printf "%d\t%d\t%d\t%s\t%s\n", SL[k], SE[k], SB[k], (SD[k] ? SD[k] : "-"), SH[k]
}
