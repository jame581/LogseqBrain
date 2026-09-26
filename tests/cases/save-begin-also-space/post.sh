grep -F -x -q "file pages/My Notes.md" "$(sb_manifest)" || { echo "manifest lacks pages/My Notes.md"; exit 1; }
