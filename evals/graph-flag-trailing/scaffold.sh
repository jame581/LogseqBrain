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
mkdir -p "$HOME/.config/logseq-brain"
printf '{ "graphPath": "%s" }\n' "$(pwd)/decoy" > "$HOME/.config/logseq-brain/config.json"
