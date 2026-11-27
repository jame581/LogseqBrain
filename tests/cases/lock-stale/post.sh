[ -z "$(find "$TMPDIR"/logseq-brain-* -name lock)" ] || { echo "lock not released"; exit 1; }
