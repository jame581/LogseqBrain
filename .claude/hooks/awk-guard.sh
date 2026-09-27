#!/bin/sh
# PostToolUse guard for skills/_shared/lib/*.awk edits.
#   awk-guard.sh portability  — sync: fail (exit 2) on gawk-only constructs that mawk/BWK awk reject.
#   awk-guard.sh tests        — asyncRewake: run the golden cases for the edited program (exit 2 on failure).
# Reads the hook JSON on stdin; any other file is a silent no-op.
mode=$1
root=${CLAUDE_PROJECT_DIR:-$(pwd)}

# file_path from the hook payload, JSON-unescaped, backslashes normalised to forward slashes
file=$(LC_ALL=C awk '
  { buf = buf $0 }
  END {
    if (!match(buf, /"file_path"[ \t]*:[ \t]*"([^"\\]|\\.)*"/)) exit
    s = substr(buf, RSTART, RLENGTH); sub(/^"file_path"[ \t]*:[ \t]*"/, "", s); sub(/"$/, "", s)
    gsub(/\\\\/, "/", s); gsub(/\\/, "/", s); print s
  }')
case $file in
  */skills/_shared/lib/*.awk) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0
prog=$(basename "$file" .awk)

if [ "$mode" = portability ]; then
  out=$(LC_ALL=C awk '
    # strip a trailing comment: first # outside a double-quoted string
    function code(s,   i, c, q, r) {
      q = 0; r = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (q && c == "\\") { r = r c substr(s, i + 1, 1); i++; continue }
        if (c == "\"") q = !q
        if (!q && c == "#") break
        r = r c
      }
      return r
    }
    { line[NR] = code($0); t = line[NR]
      while (match(t, /[A-Za-z_][A-Za-z_0-9]*\[/)) { arr[substr(t, RSTART, RLENGTH - 1)] = 1; t = substr(t, RSTART + RLENGTH) }
      t = line[NR]   # arrays created by split(s, NAME ...)
      while (match(t, /split[ \t]*\([^,]*,[ \t]*[A-Za-z_][A-Za-z_0-9]*/)) {
        nm = substr(t, RSTART, RLENGTH); sub(/^.*,[ \t]*/, "", nm); arr[nm] = 1; t = substr(t, RSTART + RLENGTH) } }
    END {
      for (n = 1; n <= NR; n++) {
        s = line[n]
        if (match(s, /(gensub|strftime|mktime|systime|asorti?|patsplit)[ \t]*\(/)) hit(n, "gawk-only function " substr(s, RSTART, RLENGTH - 1))
        if (s ~ /IGNORECASE|BEGINFILE|ENDFILE|@include|PROCINFO/) hit(n, "gawk-only keyword")
        if (s ~ /\/[^\/"]*[^\\\/"]\{[0-9]+(,[0-9]*)?\}[^\/"]*\//) hit(n, "{n,m} interval in a regex (mawk and BWK awk treat braces literally)")
        t = s
        while (match(t, /length[ \t]*\([ \t]*[A-Za-z_][A-Za-z_0-9]*[ \t]*\)/)) {
          nm = substr(t, RSTART, RLENGTH); sub(/^length[ \t]*\([ \t]*/, "", nm); sub(/[ \t]*\)$/, "", nm)
          if (nm in arr) hit(n, "length(array) on " nm " (count elements in a loop)")
          t = substr(t, RSTART + RLENGTH)
        }
        t = s
        while (match(t, /match[ \t]*\(/)) {
          t = substr(t, RSTART + RLENGTH); d = 1; c = 0; q = 0
          for (i = 1; i <= length(t) && d > 0; i++) {
            ch = substr(t, i, 1)
            if (q) { if (ch == "\\") i++; else if (ch == "\"") q = 0; continue }
            if (ch == "\"") q = 1
            else if (ch == "(") d++
            else if (ch == ")") d--
            else if (ch == "," && d == 1) c++
          }
          if (c >= 2) hit(n, "three-argument match()")
        }
      }
    }
    function hit(n, why) { printf "%s:%d: %s\n", FILENAME, n, why }
  ' "$file")
  [ -z "$out" ] && exit 0
  printf 'POSIX awk portability (CLAUDE.md: mawk/BWK awk must run this):\n%s\n' "$out" >&2
  exit 2
fi

if [ "$mode" = tests ]; then
  # lib program -> golden-case prefix; core.awk and unmapped programs are left to the full sh tests/run.sh
  case $prog in
    activity|index|journal|lint|read|search|sections|status) glob="$prog-*" ;;
    map) glob="digest-*" ;;
    *) exit 0 ;;
  esac
  out=$(cd "$root" && sh tests/run.sh "$glob" 2>&1)
  summary=$(printf '%s\n' "$out" | tail -1)
  case $summary in
    *" 0 failed"*) exit 0 ;;
  esac
  printf 'Golden cases %s failed after editing %s.awk:\n%s\n' "$glob" "$prog" "$(printf '%s\n' "$out" | grep -v '^ok ' | tail -40)" >&2
  exit 2
fi
