#!/bin/sh
# Golden-file tests for skills/_shared/bin/brain.
# Usage: sh tests/run.sh [case-name-glob]      BRAIN_AWK=mawk sh tests/run.sh
set -u
LC_ALL=C; export LC_ALL
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BRAIN="$ROOT/skills/_shared/bin/brain"
. "$ROOT/tests/lib/fixture.sh"
WORK="${TMPDIR:-/tmp}/brain-tests.$$"
rm -rf "$WORK"; mkdir -p "$WORK" || exit 2
trap 'rm -rf "$WORK"' EXIT
pass=0; fail=0
for case_dir in "$ROOT"/tests/cases/${1:-*}/; do
  [ -d "$case_dir" ] || continue
  case_dir=${case_dir%/}
  name=$(basename "$case_dir")
  run="$WORK/$name"; G="$run/graph"
  mkdir -p "$G/pages" "$G/journals" "$run/tmp" "$run/config" "$run/home"
  [ -d "$case_dir/graph" ] && cp -R "$case_dir/graph/." "$G/"
  # The test environment is exported before setup.sh, so a setup can run the helper itself
  # (e.g. `sh "$BRAIN" --graph "$G" sections …` to record a baseline in this case's TMPDIR).
  unset LOGSEQ_BRAIN_PATH
  APPDATA=; XDG_CONFIG_HOME="$run/config"; HOME="$run/home"; TMPDIR="$run/tmp"
  BRAIN_TODAY=2026-09-11; BRAIN_NOW=14:32; CASE=$case_dir
  export APPDATA XDG_CONFIG_HOME HOME TMPDIR BRAIN_TODAY BRAIN_NOW CASE G BRAIN
  if [ -f "$case_dir/setup.sh" ]; then
    if ! (cd "$G" && . "$case_dir/setup.sh"); then
      echo "FAIL $name (setup.sh)"; fail=$((fail + 1)); continue
    fi
  fi
  (
    if [ -f "$case_dir/env" ]; then
      while IFS= read -r l || [ -n "$l" ]; do [ -n "$l" ] && eval "export $l"; done < "$case_dir/env"
    fi
    eval "set -- $(cat "$case_dir/cmd")"
    if [ -f "$case_dir/no-graph-flag" ]; then sh "$BRAIN" "$@"; else sh "$BRAIN" --graph "$G" "$@"; fi \
      > "$run/out" 2> "$run/err"
    echo $? > "$run/exit"
  )
  ok=1
  want_exit=0; [ -f "$case_dir/expected.exit" ] && want_exit=$(tr -d ' \r\n' < "$case_dir/expected.exit")
  got_exit=$(cat "$run/exit")
  [ "$got_exit" = "$want_exit" ] || { ok=0; echo "  exit: want $want_exit, got $got_exit"; }
  exp=
  [ -f "$case_dir/expected.out" ] && exp="$case_dir/expected.out"
  if [ -f "$case_dir/expected.sh" ]; then
    (CASE=$case_dir G=$G . "$case_dir/expected.sh") > "$run/expected.out"; exp="$run/expected.out"
  fi
  if [ -n "$exp" ] && ! diff "$exp" "$run/out" > "$run/diff"; then
    ok=0; sed 's/^/  /' "$run/diff"
  fi
  if [ -f "$case_dir/expected.contains" ]; then
    while IFS= read -r l || [ -n "$l" ]; do
      [ -z "$l" ] && continue
      cat "$run/out" "$run/err" | grep -F -q -- "$l" || { ok=0; echo "  missing: $l"; }
    done < "$case_dir/expected.contains"
  fi
  expf=
  [ -f "$case_dir/expected.file" ] && expf="$case_dir/expected.file"
  if [ -f "$case_dir/expected.file.sh" ]; then
    (CASE=$case_dir G=$G . "$case_dir/expected.file.sh") > "$run/expected.file"; expf="$run/expected.file"
  fi
  if [ -n "$expf" ]; then
    t=$(tr -d '\r\n' < "$case_dir/target")
    if ! cmp -s "$expf" "$G/$t"; then
      ok=0; echo "  file differs: $t"; diff "$expf" "$G/$t" | sed 's/^/  /'
    fi
  fi
  if [ "$ok" = 1 ]; then pass=$((pass + 1)); echo "ok   $name"
  else fail=$((fail + 1)); echo "FAIL $name"; sed 's/^/  stderr: /' "$run/err"; fi
done
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
