# The info block is the helper's own (its awk: line differs per awk); the digest block is digest-ok's.
echo '== info'; sh "$BRAIN" --graph "$G" info
echo '== digest'; cat "$CASE/../digest-ok/expected.out"
echo '== journal'
printf '%s\n' '  - [[Projects/Dig]]: earlier work' 'coverage: 1 of 1 mention, 35 B of 90 B journal (journals/2026_09_11.md)'
echo '== activity'
echo 'activity: 14:32 loaded [[Projects/Dig]] (digest) → journals/2026_09_11.md'
