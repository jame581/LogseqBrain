# Eight more writers at once: every line must land (no lost update), none refused.
i=1; while [ "$i" -le 8 ]; do sh "$BRAIN" --graph "$G" activity "p$i" > /dev/null 2>"$RUN/err.$i" & i=$((i + 1)); done
wait
n=$(grep -c '^  - 14:32 p[0-9]$' "$G/journals/2026_09_11.md")
[ "$n" = 9 ] || { echo "want 9 activity lines, got $n"; cat "$RUN"/err.*; exit 1; }
