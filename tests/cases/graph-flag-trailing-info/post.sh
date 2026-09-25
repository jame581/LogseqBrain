# info prints the graph as the host sees it: cygpath -m form on Git for Windows, as the helper does.
want=$(cygpath -m "$G" 2>/dev/null || printf '%s' "$G")
grep -F -x -q "graph: $want" "$RUN/out" || { echo "graph: line does not name $want"; cat "$RUN/out"; exit 1; }
