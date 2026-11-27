# A live holder: this test runner's own shell ($$ is not reset in a subshell).
sh "$BRAIN" --graph "$G" status > /dev/null
d=$(echo "$TMPDIR"/logseq-brain-*/*/); printf '%s\n' "$$" > "${d}lock"
