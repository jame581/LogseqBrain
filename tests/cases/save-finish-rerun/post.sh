[ "$(grep -c -F -- '[[Projects/Dig]]: did c' "$G/journals/2026_09_11.md")" = 1 ] || { echo "Sessions bullet written twice"; exit 1; }
[ "$(grep -c 'saved \[\[Projects/Dig' "$G/journals/2026_09_11.md")" = 1 ] || { echo "activity count"; exit 1; }
