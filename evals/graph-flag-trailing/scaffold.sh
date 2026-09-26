#!/bin/sh
# ./graph is the graph the prompt names. ./decoy is a second copy that the user config points at:
# before v0.12.0, a trailing `--graph ./graph` was ignored and the helper ran against the config's
# graph, logging the load into the decoy's journal. The decoy starts with no journals at all, so any
# journal file in it afterwards was created by the run (graders/decoy-untouched.md).
# The scaffold and the run share the per-run HOME, with XDG_CONFIG_HOME unset in both (v0.12.0 spec §11).
set -e
here=$(dirname "$0")
sh "$here/../fixtures/materialize.sh" graph
sh "$here/../fixtures/materialize.sh" decoy
rm -f decoy/journals/*.md
# The decoy's Demo has no ## Digest, so a load that reached it prints `digest: missing` and can never
# satisfy graders/activity.md (the `(digest)` line): with decoy-untouched.md, two independent tells.
awk '/^- ## Digest/ { skip = 1; next } /^- ## / { skip = 0 } !skip' decoy/pages/Projects___Demo.md > decoy/demo.tmp
mv decoy/demo.tmp decoy/pages/Projects___Demo.md
if grep -q '## Digest' decoy/pages/Projects___Demo.md; then echo "scaffold: decoy digest not stripped" >&2; exit 1; fi
mkdir -p "$HOME/.config/logseq-brain"
printf '{ "graphPath": "%s" }\n' "$(pwd)/decoy" > "$HOME/.config/logseq-brain/config.json"
