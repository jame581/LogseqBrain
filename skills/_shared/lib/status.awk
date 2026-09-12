# status.awk — `brain status`: one TSV row per project/task page, from its property block only.
#   -v listfile=FILE -v today=yyyy-MM-dd   (run from the graph root; BEGIN-only, reads no stdin)
function clean(s) { gsub(/\t/, " ", s); return (s == "") ? "-" : s }

BEGIN {
  print "page\ttype\tstatus\tlast-updated\tdigest-updated\tdrift\tstaleness\tfocus\tnext\topen"
  while ((getline f < listfile) > 0) {
    for (k in P) delete P[k]
    np = 0
    while ((getline ln < f) > 0) {
      t = cr(ln)
      if (t ~ /^[ \t]*- / || heading_text(t) != "") break
      if (match(t, /^[A-Za-z0-9_][A-Za-z0-9_.-]*:: /)) { P[substr(t, 1, RLENGTH - 3)] = substr(t, RLENGTH + 1); np++ }
    }
    close(f)
    name = f; sub(/^pages\//, "", name); sub(/\.md$/, "", name); gsub(/___/, "/", name)
    istask = (f ~ /^pages\/Tasks___/)
    typ = P["type"]; st = P["status"]
    d1 = days(P["digest-updated"]); d2 = days(P["last-updated"])
    drift = (d1 >= 0 && d2 >= 0) ? d2 - d1 : "-"
    if (istask) {
      NT++
      if (st == "active") TA++; else if (st == "blocked") TB++; else if (st == "done") TD++; else TL++
      if (d1 < 0) NDT++
    } else if (typ == "project") {
      NP++; if (st == "active") NPA++
      if (d1 < 0) NDP++
    }
    if (drift != "-" && drift > 30) SDG++
    if (!np) { printf "%s\t-\t-\t-\t-\t-\tno properties — run brain-doctor\t-\t-\t-\n", name; continue }
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", name, clean(typ), clean(st), clean(P["last-updated"]), \
      clean(P["digest-updated"]), drift, staleness(P["last-updated"], st, typ, istask), clean(P["focus"]), \
      clean(P["next"]), clean(P["open"])
  }
  printf "# projects: %d (%d active) · tasks: %d (%d active, %d blocked, %d done, %d legacy) · no digest: %s, %s · stale digest: %d\n", \
    NP, NPA, NT, TA, TB, TD, TL, pl(NDP + 0, "project"), pl(NDT + 0, "task"), SDG
}
