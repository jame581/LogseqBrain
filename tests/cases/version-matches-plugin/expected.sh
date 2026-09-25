# BRAIN_VERSION in skills/_shared/bin/brain must equal .claude-plugin/plugin.json's version.
printf 'logseq-brain %s\n' "$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$CASE/../../../.claude-plugin/plugin.json")"
