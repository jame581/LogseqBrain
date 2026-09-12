mkdir -p "$XDG_CONFIG_HOME/logseq-brain"
printf '{ "graphPath": "%s", "journeyLog": false }\n' "$G" > "$XDG_CONFIG_HOME/logseq-brain/config.json"
