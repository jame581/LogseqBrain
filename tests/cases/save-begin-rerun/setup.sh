save_fixture
sh "$BRAIN" --graph "$G" save-begin Projects/Dig --also pages/Meta.md > /dev/null
m=$(find "$TMPDIR/logseq-brain" -name 'save.*.lst'); sed "s/^ts .*/ts $(( $(date +%s) - 60 ))/" "$m" > "$m.x" && mv "$m.x" "$m"
grep -q '^ts ' "$m"
