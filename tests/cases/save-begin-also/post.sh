m=$(sb_manifest); [ -n "$m" ] || { echo "no manifest"; exit 1; }
for f in pages/Meta.md pages/Decisions.md; do grep -F -x -q "file $f" "$m" || { echo "manifest lacks $f"; cat "$m"; exit 1; }; done
b=$(find "$TMPDIR/logseq-brain" -path '*/base/pages%Decisions.md')
[ -n "$b" ] && [ ! -s "$b" ] || { echo "absent file has no empty baseline"; exit 1; }
