# The graph: line is the one absolute path the helper prints (skills Read and Edit through it), and the
# state directory is keyed on it. A --graph given as "$G/../graph" or as ./graph must print the canonical
# absolute path. The eval runs pass `--graph ./graph`, and a `graph: ./graph` line cost a load an extra
# call to find the page file.
want=$(cygpath -m "$G" 2>/dev/null || printf '%s' "$G")
grep -F -x -q "graph: $want" "$RUN/out" || { echo "want graph: $want"; cat "$RUN/out"; exit 1; }
(cd "$RUN" && sh "$BRAIN" --graph ./graph info) > "$RUN/rel.out" 2>&1 || { cat "$RUN/rel.out"; exit 1; }
grep -F -x -q "graph: $want" "$RUN/rel.out" || { echo "relative: want graph: $want"; cat "$RUN/rel.out"; exit 1; }
