! grep -q 'Projects___Y' "$RUN/out" || { echo "the Y page's save leaked into this one"; exit 1; }
grep -q -F -- '  - [[Projects/Y]]: did y' "$G/journals/2026_09_11.md" || { echo "first save missing"; exit 1; }
