m=$(sb_manifest)
for f in pages/Meta.md pages/Decisions.md pages/Index.md; do grep -F -x -q "file $f" "$m" || { echo "manifest lacks $f"; cat "$m"; exit 1; }; done
[ "$(grep -c '^file pages/Index.md$' "$m")" = 1 ] || { echo "duplicate file lines"; cat "$m"; exit 1; }
t=$(sed -n 's/^ts //p' "$m"); [ "$t" -ge $(( $(date +%s) - 30 )) ] || { echo "ts not refreshed: $t"; exit 1; }
