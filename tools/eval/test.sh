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
# The call targets gate (v0.12.0 spec §5): every grader passed, but load-digest took 5 calls > 4.
"$PY" "$HERE/summarize.py" table "$T/result-over.json" > "$out" 2>&1
check summarize-table-over-target 1 $? "$T/expected-table-over.txt" "$out"
"$PY" "$HERE/summarize.py" table "$T/result-ok.json" > "$out" 2>&1
check summarize-table-within-target 0 $? "$T/expected-table-ok.txt" "$out"

"$PY" "$HERE/summarize.py" traces "$T/result.json" > "$out.raw" 2>&1; rc=$?
sed "s#$T/##" "$out.raw" > "$out"
printf 'load-digest\t1\ttrace-load.jsonl\nsave-basic\t1\ttrace-save.jsonl\n' > "$out.want"
check summarize-traces 0 "$rc" "$out.want" "$out"
"$PY" "$HERE/summarize.py" breakdown "$T/trace-breakdown.jsonl" > "$out" 2>&1
check summarize-breakdown 0 $? "$T/expected-breakdown.txt" "$out"

"$PY" "$HERE/summarize.py" bogus > "$out" 2>&1; rc=$?
if [ "$rc" = 2 ] && grep -q 'summarize.py table RESULT_JSON' "$out"; then echo "ok   summarize-usage"
else echo "FAIL summarize-usage: exit $rc: $(cat "$out")"; fail=1; fi

# passed: load-digest scored 1 (pass), save-basic 0.5 (fail), isolation-canary is absent (fail).
for c in load-digest:0 save-basic:1 isolation-canary:1; do
  "$PY" "$HERE/summarize.py" passed "$T/result.json" "${c%%:*}" > "$out" 2>&1; rc=$?
  if [ "$rc" = "${c#*:}" ]; then echo "ok   summarize-passed ${c%%:*}"
  else echo "FAIL summarize-passed ${c%%:*}: exit want ${c#*:}, got $rc: $(cat "$out")"; fail=1; fi
done

REPO=$(cd "$HERE/../.." && pwd)
# Case files: every grader regex compiles and every scaffold exists (the harness's $0 --check checks schema only).
"$PY" "$HERE/lint_cases.py" "$REPO/evals" > "$out" 2>&1; rc=$?
if [ "$rc" = 0 ]; then echo "ok   case-lint: $(tail -n 1 "$out")"
else cat "$out"; echo "FAIL case-lint"; fail=1; fi

# Every scaffold builds a complete graph the way the harness runs it: bash, a bare environment, an empty cwd.
for s in "$REPO"/evals/*/scaffold.sh; do
  [ -f "$s" ] || continue
  c=$(basename "$(dirname "$s")"); w=$(mktemp -d) || exit 2
  mkdir -p "$w/cwd" "$w/home"
  # graph-flag-trailing's decoy only proves anything with the user config written and no digest to load.
  extra=true
  [ "$c" = graph-flag-trailing ] && extra='[ -s "$w/home/.config/logseq-brain/config.json" ] && ! grep -q "## Digest" "$w/cwd/decoy/pages/Projects___Demo.md"'
  if (cd "$w/cwd" && env -i HOME="$w/home" PATH=/usr/bin:/bin bash "$s") > "$w/log" 2>&1 \
     && [ -f "$w/cwd/graph/pages/Index.md" ] && ! grep -rq '@TODAY' "$w/cwd/graph" && eval "$extra"; then
    echo "ok   scaffold $c"
  else
    echo "FAIL scaffold $c: $(cat "$w/log")"; fail=1
  fi
  rm -rf "$w"
done

# run.sh refuses anyone but logseq-eval, before it touches anything.
if [ "$(id -un)" != logseq-eval ]; then
  sh "$HERE/run.sh" --dry-run > "$out" 2>&1; rc=$?
  if [ "$rc" = 2 ] && grep -q 'logseq-eval' "$out"; then echo "ok   run-refuses-other-user"
  else echo "FAIL run-refuses-other-user: exit $rc: $(cat "$out")"; fail=1; fi
fi
sh "$HERE/run.sh" --bogus > "$out" 2>&1; rc=$?
if [ "$rc" = 2 ] && grep -q 'unknown argument' "$out"; then echo "ok   run-rejects-unknown-argument"
else echo "FAIL run-rejects-unknown-argument: exit $rc: $(cat "$out")"; fail=1; fi

[ "$fail" = 0 ] && echo "all tools/eval checks passed"
exit "$fail"
