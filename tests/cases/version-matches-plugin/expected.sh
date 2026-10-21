# BRAIN_VERSION in plugin/skills/_shared/bin/brain must equal plugin/.claude-plugin/plugin.json's version.
printf 'logseq-brain %s\n' "$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$CASE/../../../plugin/.claude-plugin/plugin.json")"
