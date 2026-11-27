# A holder that is gone: a finished child's pid.
sh "$BRAIN" --graph "$G" status > /dev/null
sh -c 'exit 0' & p=$!; wait "$p"
d=$(echo "$TMPDIR"/logseq-brain-*/*/); mkdir "${d}lock" && printf '%s\n' "$p" > "${d}lock/pid"
