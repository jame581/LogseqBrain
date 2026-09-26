# index.awk — pages/Index.md with the page's one-liner parenthetical replaced, or appended when it has
# none. Name in ENVIRON["BRAIN_NAME"], the new parenthetical's text in ENVIRON["BRAIN_PAREN"].
#   -v nonl=0|1
# The one-liner is found as save-begin's anchor finds it (index_lines). Its parenthetical is a " (…)"
# that closes the line: the "(" matching the final ")" and preceded by a space, so a trailing markdown
# link "[x](https://…)" is never taken for one. A trailing \r is kept.
# Exit 3: no such line (stdout: "missing"); exit 4: several (stdout: "ambiguous (n lines: a,b)").
{ L[++N] = $0 }
END {
  NONL = nonl; scan()
  index_lines(ENVIRON["BRAIN_NAME"])
  if (IDXN == 0) { print "missing"; exit 3 }
  if (IDXN > 1) {
    s = IDX[1]; for (j = 2; j <= IDXN; j++) s = s "," IDX[j]
    printf "ambiguous (%d lines: %s)\n", IDXN, s; exit 4
  }
  i = IDX[1]; t = L[i]; crs = ""
  if (t ~ /\r$/) { crs = "\r"; sub(/\r$/, "", t) }
  # Trailing whitespace is kept but set aside: a parenthetical followed by spaces still closes the line.
  tws = ""; if (match(t, /[ \t]+$/)) { tws = substr(t, RSTART); t = substr(t, 1, RSTART - 1) }
  crs = tws crs
  paren = "(" ENVIRON["BRAIN_PAREN"] ")"
  j = 0
  if (substr(t, length(t), 1) == ")") {
    depth = 0
    for (j = length(t); j >= 1; j--) {
      c = substr(t, j, 1)
      if (c == ")") depth++
      else if (c == "(" && --depth == 0) break
    }
    if (j < 2 || substr(t, j - 1, 1) != " ") j = 0
  }
  L[i] = (j ? substr(t, 1, j - 1) paren : t " " paren) crs
  for (k = 1; k <= N; k++) { printf "%s", L[k]; if (k < N || !NONL) printf "\n" }
}
