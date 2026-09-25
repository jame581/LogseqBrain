[ -z "$(sb_manifest)" ] || { echo "a manifest was written"; exit 1; }
n=$(find "$TMPDIR/logseq-brain" -path '*/base/*' -type f 2>/dev/null | wc -l | tr -d ' ')
[ "$n" = 0 ] || { echo "$n baseline file(s) recorded"; exit 1; }
