# Replace every 10-byte date token with a 10-byte date, so byte figures survive the substitution:
#   @TODAY-NN@ -> yyyy-MM-dd   and   @TODAY_NN@ -> yyyy_MM_dd   (NN = days before `today`).
# Usage: awk -v BINMODE=3 -v today=yyyy-MM-dd -f dates.awk FILE
# POSIX awk only (no mktime/strftime, no {n,m} intervals): mawk, BWK awk and gawk all run it.
function days(y, m, d,   era, yoe, doy) {                 # civil date -> days since 1970-01-01
  y -= (m <= 2); era = int(y / 400); yoe = y - era * 400
  doy = int((153 * (m > 2 ? m - 3 : m + 9) + 2) / 5) + d - 1
  return era * 146097 + yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy - 719468
}
function civil(z, sep,   era, doe, yoe, doy, mp, d, m, y) {  # days since 1970-01-01 -> civil date
  z += 719468; era = int(z / 146097); doe = z - era * 146097
  yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
  doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100))
  mp = int((5 * doy + 2) / 153); d = doy - int((153 * mp + 2) / 5) + 1
  m = mp < 10 ? mp + 3 : mp - 9; y = yoe + era * 400 + (m <= 2)
  return sprintf("%04d%s%02d%s%02d", y, sep, m, sep, d)
}
BEGIN {
  if (today !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) { print "dates.awk: bad today: " today > "/dev/stderr"; exit 2 }
  split(today, t, "-"); base = days(t[1] + 0, t[2] + 0, t[3] + 0)
}
{
  s = $0; out = ""
  while (match(s, /@TODAY[-_][0-9][0-9]@/)) {
    tok = substr(s, RSTART, RLENGTH)
    out = out substr(s, 1, RSTART - 1) civil(base - substr(tok, 8, 2), substr(tok, 7, 1))
    s = substr(s, RSTART + RLENGTH)
  }
  print out s
}
