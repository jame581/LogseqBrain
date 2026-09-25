b=$(find "$TMPDIR/logseq-brain" -path '*/base/pages%Meta.md')
cmp -s "$b" "$G/pages/Meta.md" || { echo "the inherited pages/Meta.md was not re-baselined"; diff "$b" "$G/pages/Meta.md"; exit 1; }
grep -F -x -q 'file pages/Meta.md' "$(sb_manifest)" || { echo "manifest lost pages/Meta.md"; exit 1; }
