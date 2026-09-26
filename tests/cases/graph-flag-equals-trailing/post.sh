# info prints the graph as the host sees it: cygpath -m form on Git for Windows, as the helper does.
# $G is taken canonically, as the helper resolves it: macOS's TMPDIR ends in "/", so $G holds a "//".
g=$(cd "$G" && pwd); want=$(cygpath -m "$g" 2>/dev/null || printf '%s' "$g")
grep -F -x -q "graph: $want" "$RUN/out" || { echo "graph: line does not name $want"; cat "$RUN/out"; exit 1; }
