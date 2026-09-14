#!/bin/sh
# Offline checks for tools/eval — no model calls, no WSL user needed: sh tools/eval/test.sh
set -u
LC_ALL=C; export LC_ALL
HERE=$(cd "$(dirname "$0")" && pwd)
PY=${PYTHON:-python3}
T="$HERE/testdata"
fail=0
check() {  # NAME WANT_EXIT GOT_EXIT EXPECTED_FILE GOT_FILE
  if [ "$2" != "$3" ]; then echo "FAIL $1: exit want $2, got $3"; fail=1; fi
  if ! diff "$4" "$5"; then echo "FAIL $1: output differs (above)"; fail=1; fi
  [ "$2" = "$3" ] && cmp -s "$4" "$5" && echo "ok   $1"
}
out=$(mktemp) || exit 2
trap 'rm -f "$out" "$out.raw" "$out.want"' EXIT

"$PY" "$HERE/summarize.py" table "$T/result.json" > "$out" 2>&1
check summarize-table 1 $? "$T/expected-table.txt" "$out"

"$PY" "$HERE/summarize.py" traces "$T/result.json" > "$out.raw" 2>&1; rc=$?
sed "s#$T/##" "$out.raw" > "$out"
printf 'load-digest\t1\ttrace-load.jsonl\nsave-basic\t1\ttrace-save.jsonl\n' > "$out.want"
check summarize-traces 0 "$rc" "$out.want" "$out"

"$PY" "$HERE/summarize.py" bogus > "$out" 2>&1; rc=$?
if [ "$rc" = 2 ] && grep -q 'summarize.py table RESULT_JSON' "$out"; then echo "ok   summarize-usage"
else echo "FAIL summarize-usage: exit $rc: $(cat "$out")"; fail=1; fi

# passed: load-digest scored 1 (pass), save-basic 0.5 (fail), isolation-canary is absent (fail).
for c in load-digest:0 save-basic:1 isolation-canary:1; do
  "$PY" "$HERE/summarize.py" passed "$T/result.json" "${c%%:*}" > "$out" 2>&1; rc=$?
  if [ "$rc" = "${c#*:}" ]; then echo "ok   summarize-passed ${c%%:*}"
  else echo "FAIL summarize-passed ${c%%:*}: exit want ${c#*:}, got $rc: $(cat "$out")"; fail=1; fi
done

[ "$fail" = 0 ] && echo "all tools/eval checks passed"
exit "$fail"
