save_fixture
sf_begin Projects/Dig
m=$(find "$TMPDIR/logseq-brain" -name 'save.*.lst'); sed "s/^ts .*/ts $(( $(date +%s) - 46800 ))/" "$m" > "$m.x" && mv "$m.x" "$m"
sf_add pages/Projects___Dig.md '  - 2026-09-11: c'
