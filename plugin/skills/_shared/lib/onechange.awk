# onechange.awk — exit 0 iff NEW differs from OLD only inside one contiguous region of at most
# max_old old lines and max_new new lines, every new line in it matching `want` (an ERE) if given.
#   awk -v BINMODE=3 -v max_old=N -v max_new=M [-v want=ERE] -f onechange.awk OLD NEW
# Lines are compared as strings (… "") — array copies of $0 are strnums, and "1.0" == "1" numerically.
FILENAME == ARGV[1] { A[++na] = $0; next }
{ B[++nb] = $0 }
END {
  p = 0; while (p < na && p < nb && (A[p + 1] "") == (B[p + 1] "")) p++
  s = 0; while (s < na - p && s < nb - p && (A[na - s] "") == (B[nb - s] "")) s++
  if (na - p - s > max_old + 0 || nb - p - s > max_new + 0) {
    printf "brain: refusing to write — %d line(s) would be replaced and %d written (allowed: %d, %d)\n", \
      na - p - s, nb - p - s, max_old, max_new > "/dev/stderr"
    exit 1
  }
  if (want != "") {
    # The loop below is vacuous when the region holds no new lines at all: old=a,b,c → new=a,c
    # passed with the Map regex set, and a one-line file could be emptied. map.awk cannot delete a
    # line today, so this is defence in depth on the write guard.
    if (nb - s < p + 1) {
      printf "brain: refusing to write — the change writes no new line where one was expected\n" > "/dev/stderr"
      exit 1
    }
    for (i = p + 1; i <= nb - s; i++)
      if (B[i] !~ want) {
        printf "brain: refusing to write — changed line %d is not the expected kind\n", i > "/dev/stderr"
        exit 1
      }
  }
}
