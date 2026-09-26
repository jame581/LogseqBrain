b() { sh "$BRAIN" --graph "$G" "$@"; }
echo '== info'; b info
echo '== sections'; b sections Projects/Dig --baseline pages/Index.md journals/2026_09_11.md
echo '== digest'; b digest Projects/Dig
echo '== session-log'; b tail Projects/Dig 'Session Log' --entries 1 --max 4096
echo '== current-plan'; b read Projects/Dig 'Current Plan'
echo '== anchors'
echo 'index: 4   - [[Projects/Dig]] — test page (v1 — digest)'
echo 'sessions: heading at 1, last line at 2'
