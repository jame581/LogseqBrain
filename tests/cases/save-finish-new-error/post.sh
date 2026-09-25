grep -q -F -- '  - [[Projects/Dig]]: did c' "$G/journals/2026_09_11.md" || { echo "Sessions bullet not written"; exit 1; }
! grep -q 'saved \[\[Projects/Dig' "$G/journals/2026_09_11.md" || { echo "activity written despite a new error"; exit 1; }
[ -n "$(sb_manifest)" ] || { echo "manifest dropped: the printed brain check has no baselines"; exit 1; }
