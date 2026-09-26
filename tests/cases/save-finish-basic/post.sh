[ "$(sf_blocks)" = '== sessions == index == map == check == activity ' ] || { echo "blocks: $(sf_blocks)"; exit 1; }
sf_only_map "$TMPDIR/edited.md" "$G/pages/Projects___Dig.md" || exit 1
grep -q '^  - Map: Session Log | 4 KB (3 entries)' "$G/pages/Projects___Dig.md" || { echo "Map not refreshed"; grep Map: "$G/pages/Projects___Dig.md"; exit 1; }
[ -z "$(sb_manifest)" ] || { echo "manifest kept after a completed save"; exit 1; }
