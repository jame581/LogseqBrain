m=$(sb_manifest)
[ "$(basename "$m")" = 'save.pages%Projects___Dig.md.lst' ] || { echo "manifest name: $m"; exit 1; }
printf '%s\n' 'page pages/Projects___Dig.md' 'file pages/Projects___Dig.md' 'file pages/Index.md' \
  'file journals/2026_09_11.md' 'file pages/Meta.md' > "$RUN/want"
grep -v '^ts ' "$m" | diff "$RUN/want" - || { echo "manifest body differs"; exit 1; }
grep -q '^ts [0-9][0-9]*$' "$m" || { echo "no ts line"; exit 1; }
