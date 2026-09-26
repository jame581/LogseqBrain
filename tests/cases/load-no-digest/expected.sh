echo '== info'; sh "$BRAIN" --graph "$G" info
echo '== digest'; cat "$CASE/../digest-none/expected.out"
echo '== journal'; echo 'coverage: no journal for 2026-09-11 (journals/2026_09_11.md)'
echo "activity: not written — no digest; run the fallback reads, then brain activity 'loaded [[Projects/None]] (brief)'"
