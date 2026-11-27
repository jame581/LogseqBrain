# A stale lock that eight writers find at once: exactly one may break it, then all must land in turn.
sh -c 'exit 0' & p=$!; wait "$p"
d=$(echo "$TMPDIR"/logseq-brain-*/*/); printf '%s\n' "$p" > "${d}lock"
i=1; while [ "$i" -le 8 ]; do sh "$BRAIN" --graph "$G" activity "p$i" > /dev/null 2>"$RUN/err.$i" & i=$((i + 1)); done
wait
n=$(grep -c '^  - 14:32 p[0-9]$' "$G/journals/2026_09_11.md")
[ "$n" = 9 ] || { echo "want 9 activity lines, got $n"; cat "$RUN"/err.*; exit 1; }
[ -z "$(find "$TMPDIR"/logseq-brain-* -name 'lock*')" ] || { echo "lock not released"; exit 1; }
