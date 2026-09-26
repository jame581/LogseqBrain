# Full mode records no baselines (it runs the table engine, not cmd_sections) and logs nothing:
# the model writes (full) after its own reads.
! grep -q '^# baseline saved' "$RUN/out" || { echo "a baseline line was printed"; exit 1; }
! grep -q '^== activity\|^activity:' "$RUN/out" || { echo "an activity line was printed"; exit 1; }
n=$(find "$TMPDIR/logseq-brain" -path '*/base/*' -type f 2>/dev/null | wc -l | tr -d ' ')
[ "$n" = 0 ] || { echo "$n baseline file(s) recorded"; exit 1; }
