printf '%s\n' 'status:: active' '- ## Notes' '  - old PR #12' > pages/Tasks___Chk.md
sh "$BRAIN" --graph "$G" sections Tasks/Chk > /dev/null
printf '%s\n' '  - new PR #13 and [[CRMGM-9]]' >> pages/Tasks___Chk.md
for ts in "$TMPDIR"/logseq-brain/*/base/pages%Tasks___Chk.md.ts; do printf '123x' > "$ts"; done
