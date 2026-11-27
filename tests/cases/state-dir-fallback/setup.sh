# $TMPDIR unwritable (Claude Code's sandbox can do this): the next candidate is used.
printf 'x' > "$TMPDIR/../notadir"
