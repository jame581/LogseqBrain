# A bare relative --graph names the working directory's folder, never one found through CDPATH:
# `cd graph` searches CDPATH first, and an exported CDPATH with its own graph/ would redirect the helper
# to another graph (second v0.12.0 review). The case runs from $G/.. with a decoy cdp/graph on CDPATH.
mkdir -p "$G/../cdp/graph/pages"
g=$(cd "$G" && pwd); want=$(cygpath -m "$g" 2>/dev/null || printf '%s' "$g")
(cd "$G/.." && CDPATH="$G/../cdp" && export CDPATH && sh "$BRAIN" --graph graph info) > "$RUN/cdp.out" 2>&1 \
  || { cat "$RUN/cdp.out"; exit 1; }
grep -F -x -q "graph: $want" "$RUN/cdp.out" || { echo "want graph: $want"; cat "$RUN/cdp.out"; exit 1; }
