#!/bin/sh
# Run the logseq-brain eval suite (evals/) against the COMMITTED plugin — WSL2 only, as the
# dedicated logseq-eval user. Design: docs/superpowers/specs/2026-09-13-eval-suite-design.md §8.
#   wsl -d FedoraLinux-44 -u logseq-eval sh /mnt/d/AI/logseq-brain/tools/eval/run.sh [--case <glob>] [MODE]
# MODE (all but the default are free — no model call):
#   (none)         run the suite
#   --check        load every case with the real flags and a $0 ceiling: reports case files that fail
#                  schema validation and graders that cannot pass with the granted tools; starts no run.
#                  Regexes and scaffolds are checked by tools/eval/test.sh, not here.
#   --dry-run      every step except calling the harness
#   --trip-canary  a dry run that changes the sentinels on purpose; must exit 3
# Exit: 0 every case passed (or --check clean) and the canary is clean · 1 a case failed (or --check
# found problems) · 2 refused, partial, the harness failed before scoring, or another environment error
# · 3 the canary tripped (outranks the rest).
set -u
LC_ALL=C; export LC_ALL
# `wsl -u` starts a non-login shell: no ~/.local/bin, and the Windows PATH appended. Pin a Linux PATH.
PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"; export PATH
MODEL=claude-opus-5
JUDGE_MODEL=claude-haiku-4-5
MIN_CLAUDE=2.1.269
CEILING_USD=10
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
TAB=$(printf '\t')

die() { echo "run.sh: $*" >&2; exit 2; }

CASE_GLOB=; MODE=run
while [ $# -gt 0 ]; do
  case $1 in
    --case) [ $# -ge 2 ] || die "--case needs a glob"; CASE_GLOB=$2; shift 2 ;;
    --check) MODE=check; shift ;;
    --dry-run) MODE=dry; shift ;;
    --trip-canary) MODE=trip; shift ;;
    *) die "unknown argument: $1 (usage: run.sh [--case <glob>] [--check | --dry-run | --trip-canary])" ;;
  esac
done
[ "$MODE" != check ] || CEILING_USD=0

version_ge() {  # A B — true when dotted version A >= B
  awk -v a="$1" -v b="$2" 'BEGIN { split(a, x, "."); split(b, y, ".")
    for (i = 1; i <= 3; i++) { if (x[i] + 0 > y[i] + 0) exit 0; if (x[i] + 0 < y[i] + 0) exit 1 }
    exit 0 }'
}

# 1. Refuse to start anywhere but the dedicated WSL user.
[ "$(uname -s)" = Linux ] || die "Linux (WSL2) only — native Windows refuses Bash-granting eval runs"
[ "$(id -un)" = logseq-eval ] || die "run as the logseq-eval WSL user, not $(id -un) — see evals/README.md"
if [ -e "$HOME/.docker" ] || [ -L "$HOME/.docker" ]; then
  die "$HOME/.docker exists — the eval sandbox refuses to run while it holds a symlink; logseq-eval must not have one"
fi
command -v claude > /dev/null 2>&1 || die "claude not found (expected in $HOME/.local/bin)"
CLAUDE_VER=$(claude --version < /dev/null 2>/dev/null | awk 'NR == 1 { print $1 }')
version_ge "${CLAUDE_VER:-0}" "$MIN_CLAUDE" || die "Claude Code $MIN_CLAUDE or newer required (found ${CLAUDE_VER:-none})"
for t in git tar python3 cksum; do command -v "$t" > /dev/null 2>&1 || die "$t not found"; done
for t in bwrap socat; do command -v "$t" > /dev/null 2>&1 || die "$t not found — the sandbox backend needs bubblewrap and socat"; done

# 2. Export the committed payload, so uncommitted edits never leak into a release gate.
STAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
WORK=$(mktemp -d "$HOME/logseq-eval-run.XXXXXX") || die "cannot create a work directory"
: > "$WORK/.start"   # never touched again: the age reference for run directories this invocation created
CAN_TMP=; CAN_WIN=; OUT=; COPIED=0; KEPT="$WORK/kept.lst"
collect_kept() {  # the run directories the harness kept: from its log, the result's trace paths, and /tmp
  : > "$KEPT"
  [ ! -f "$OUT/run.log" ] || grep -o 'kept /tmp/claude-eval-[A-Za-z0-9]*' "$OUT/run.log" | cut -d' ' -f2 >> "$KEPT"
  [ ! -f "$OUT/result.json" ] || python3 "$HERE/summarize.py" traces "$OUT/result.json" 2>/dev/null \
    | cut -f3 | sed 's#/out/trace\.jsonl$##' >> "$KEPT"
  # A run that errored has no trace path, and --json may print no "kept" line: sweep this user's
  # run directories created since this invocation started.
  find /tmp -maxdepth 1 -type d -name 'claude-eval-*' -user "$(id -un)" -newer "$WORK/.start" 2>/dev/null >> "$KEPT"
}
cleanup() {
  # 8. Remove the kept run directories (the harness seals them read-only), the sentinels, the copy.
  # An interrupted run has not reached step 7: keep what the harness wrote, as <stamp>-partial.
  if [ "$MODE" = run ] && [ "$COPIED" = 0 ] && [ -n "$OUT" ] && [ -f "$OUT/run.log" ]; then
    mkdir -p "$REPO/evals/results/$STAMP-partial" && cp "$OUT"/* "$REPO/evals/results/$STAMP-partial/" 2>/dev/null
  fi
  if [ -n "$OUT" ]; then
    collect_kept
    sort -u "$KEPT" | while IFS= read -r d; do
      case $d in /tmp/claude-eval-?*) chmod -R u+rwX "$d" 2>/dev/null; rm -rf "$d" ;; esac
    done
  fi
  [ -z "$CAN_TMP" ] || rm -rf "$CAN_TMP"
  [ -z "$CAN_WIN" ] || rm -rf "$CAN_WIN"
  rm -rf "$WORK"
}
trap cleanup EXIT
trap 'exit 130' INT TERM
# The repo is owned by the Windows user. drvfs reports every file executable, so Linux git must ignore
# file modes, and --no-optional-locks keeps `status` from rewriting the Windows index.
repo_git() { git -c safe.directory="$REPO" -c core.filemode=false --no-optional-locks -C "$REPO" "$@"; }
SHA=$(repo_git rev-parse --short HEAD 2>/dev/null) || die "not a git repository: $REPO"
PLUGIN="$WORK/logseq-brain"; mkdir -p "$PLUGIN"
repo_git archive --format=tar HEAD .claude-plugin skills evals | tar -x -C "$PLUGIN" 2>/dev/null
[ -f "$PLUGIN/.claude-plugin/plugin.json" ] && [ -d "$PLUGIN/evals" ] || die "could not export .claude-plugin, skills and evals from HEAD ($SHA)"
rm -rf "$PLUGIN/evals/results"
DIRTY=$(repo_git status --porcelain -- .claude-plugin skills evals 2>/dev/null)

# 3. Canary sentinels outside the run workspace, proven writable by this user before the run.
seed() { printf 'ORIGINAL\n' > "$1/edit-target.txt" && touch "$1/.writable" && rm "$1/.writable"; }
snapshot() { (cd "$1" && ls -A && find . -type f -exec cksum {} + | sort) 2>&1; }
CAN_TMP=$(mktemp -d /tmp/logseq-eval-canary.XXXXXX) || die "cannot create the /tmp canary"
seed "$CAN_TMP" || die "the /tmp canary is not writable"
WIN_BASE=${EVAL_CANARY_WINDIR:-}
if [ -z "$WIN_BASE" ] && [ -x /mnt/c/Windows/System32/cmd.exe ]; then
  # cmd.exe reads stdin even for /c: without < /dev/null it swallows whatever feeds this script.
  WIN_TEMP=$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c 'echo %TEMP%' < /dev/null 2>/dev/null | tr -d '\r')
  [ -z "$WIN_TEMP" ] || WIN_BASE=$(wslpath -u "$WIN_TEMP" 2>/dev/null)
fi
if [ -n "$WIN_BASE" ] && [ -d "$WIN_BASE" ]; then
  CAN_WIN=$(mktemp -d "$WIN_BASE/logseq-eval-canary.XXXXXX" 2>/dev/null) || CAN_WIN=
  if [ -n "$CAN_WIN" ] && ! seed "$CAN_WIN"; then rm -rf "$CAN_WIN"; CAN_WIN=; fi
fi
WIN_NOTE=
[ -n "$CAN_WIN" ] || WIN_NOTE="canary: Windows-mount half SKIPPED — no writable Windows directory (set EVAL_CANARY_WINDIR)"
snapshot "$CAN_TMP" > "$WORK/canary-tmp.pre"
[ -z "$CAN_WIN" ] || snapshot "$CAN_WIN" > "$WORK/canary-win.pre"
EVAL_CANARY_TMP=$CAN_TMP; EVAL_CANARY_WIN=$CAN_WIN; export EVAL_CANARY_TMP EVAL_CANARY_WIN

# 4. Run the suite with the fixed flags (spec §3.4). The target comes first: --allow-tools takes a list.
OUT="$WORK/out"; mkdir -p "$OUT"
set -- "$PLUGIN" --runs 1 --ablation none --scaffold --allow-tools Bash Write Edit --keep-temp \
  --no-publish --trust-plugin --max-cost-usd "$CEILING_USD" --model "$MODEL" --judge-model "$JUDGE_MODEL"
[ -z "$CASE_GLOB" ] || set -- "$@" --case "$CASE_GLOB"
set -- "$@" --output-dir "$OUT" --json "$OUT/result.json"
echo "logseq-brain eval · $MODE · HEAD $SHA · Claude Code $CLAUDE_VER · $MODEL${CASE_GLOB:+ · --case $CASE_GLOB}"
[ -z "$DIRTY" ] || echo "note: uncommitted changes under .claude-plugin/, skills/ or evals/ are NOT evaluated"
case $MODE in
  dry|trip)
    echo "dry run — would run: claude plugin eval $*"
    if [ "$MODE" = trip ]; then
      echo "trip-canary: changing the sentinels on purpose"
      printf 'EDITED\n' > "$CAN_TMP/edit-target.txt"
      [ -z "$CAN_WIN" ] || printf 'x\n' > "$CAN_WIN/write-tool.txt"
    fi
    EVAL_RC=0 ;;
  *)
    [ "$MODE" = check ] || echo "running (quiet under --json; roughly 1-3 minutes per case)"
    (cd "$WORK" && claude plugin eval "$@") < /dev/null > "$OUT/run.log" 2>&1
    EVAL_RC=$? ;;
esac

# 5. Check the sentinels from outside the sandbox.
CANARY_RC=0
snapshot "$CAN_TMP" > "$WORK/canary-tmp.post"
cmp -s "$WORK/canary-tmp.pre" "$WORK/canary-tmp.post" || CANARY_RC=3
if [ -n "$CAN_WIN" ]; then
  snapshot "$CAN_WIN" > "$WORK/canary-win.post"
  cmp -s "$WORK/canary-win.pre" "$WORK/canary-win.post" || CANARY_RC=3
fi

if [ "$MODE" = check ]; then
  # A $0 ceiling starts no run, so the harness exits 2 (partial) even when every case loads. It exits 1
  # when a case file failed to load or no case was found, and reports why on stderr (in run.log).
  cat "$OUT/run.log"
  [ "$CANARY_RC" = 0 ] || exit 3
  if [ "$EVAL_RC" = 1 ] || grep -q -e 'failed to load' -e 'cannot pass' -e 'No eval cases found' "$OUT/run.log"; then
    echo "check: problems found (above)"; exit 1
  fi
  if [ "$EVAL_RC" != 2 ] || [ ! -f "$OUT/result.json" ]; then
    echo "check: unexpected harness exit $EVAL_RC"; exit 2
  fi
  echo "check: every selected case passes schema validation and no grader is impossible with the granted tools (regexes and scaffolds: sh tools/eval/test.sh)"
  exit 0
fi

# 6. Tool calls per run and the summary table (spec §7).
SUMMARY="$OUT/summary.txt"
{
  echo "logseq-brain eval · $STAMP · HEAD $SHA · Claude Code $CLAUDE_VER · $MODEL${CASE_GLOB:+ · --case $CASE_GLOB}"
  if [ -f "$OUT/result.json" ]; then python3 "$HERE/summarize.py" table "$OUT/result.json"
  elif [ "$MODE" != run ]; then echo "dry run: no result"
  else echo "no result.json — the harness failed before scoring; run.log follows"; cat "$OUT/run.log"; fi
  if [ "$CANARY_RC" = 0 ]; then
    echo "canary: sentinels unchanged (/tmp${CAN_WIN:+ and Windows mount})"
    # Unchanged sentinels prove confinement only if isolation-canary tried to change them and passed.
    if [ "$MODE" = run ]; then
      if [ -f "$OUT/result.json" ] && python3 "$HERE/summarize.py" passed "$OUT/result.json" isolation-canary; then
        echo "canary: confinement re-proven — isolation-canary attempted the writes and passed"
      else
        echo "canary: confinement NOT re-proven — isolation-canary was not selected or did not pass"
      fi
    fi
  else
    echo "CANARY TRIPPED: a sentinel outside the workspace changed during the run"
    diff "$WORK/canary-tmp.pre" "$WORK/canary-tmp.post"
    [ -z "$CAN_WIN" ] || diff "$WORK/canary-win.pre" "$WORK/canary-win.post"
  fi
  [ -z "$WIN_NOTE" ] || echo "$WIN_NOTE"
  echo "claude plugin eval exit: $EVAL_RC"
} > "$SUMMARY" 2>&1
cat "$SUMMARY"

# 7. Copy the results into the repo (evals/results/ is gitignored).
if [ "$MODE" = run ]; then
  DEST="$REPO/evals/results/$STAMP"
  if mkdir -p "$DEST/traces"; then
    for f in result.json summary.txt run.log report.html; do [ ! -f "$OUT/$f" ] || cp "$OUT/$f" "$DEST/"; done
    if [ -f "$OUT/result.json" ]; then
      python3 "$HERE/summarize.py" traces "$OUT/result.json" > "$WORK/traces.lst"
      while IFS=$TAB read -r name run path; do
        [ ! -f "$path" ] || cp "$path" "$DEST/traces/$name-$run.jsonl"
      done < "$WORK/traces.lst"
    fi
    COPIED=1
    echo "results: $DEST"
  else
    echo "run.sh: could not write $DEST — the results are removed with the work directory" >&2
  fi
fi

[ "$CANARY_RC" = 0 ] || exit 3
# Harness exit 1 without a result means the run never started (bad option, untrusted directory).
case $EVAL_RC in 0) exit 0 ;; 1) [ -f "$OUT/result.json" ] && exit 1; exit 2 ;; *) exit 2 ;; esac
