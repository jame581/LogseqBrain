grep -q "^graph: $G\$" "$RUN/out" || { echo "graph: line does not name \$G"; cat "$RUN/out"; exit 1; }
