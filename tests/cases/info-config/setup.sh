# $G/../config is the XDG_CONFIG_HOME the harness gives the command. Never touch the host's real config.
mkdir -p "$G/../config/logseq-brain"
printf '{\n  "graphPath": "%s",\n  "journeyLog": true\n}\n' "$G" > "$G/../config/logseq-brain/config.json"
