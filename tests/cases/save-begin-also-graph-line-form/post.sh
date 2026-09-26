grep -F -x -q "file pages/Meta.md" "$(sb_manifest)" || { echo "manifest lacks pages/Meta.md"; cat "$(sb_manifest)"; exit 1; }
