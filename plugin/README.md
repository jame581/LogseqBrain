# Logseq Brain

Persistent memory for Claude using a dedicated [Logseq](https://logseq.com) graph (Logseq OG, the markdown version). Save and load project context, decisions, and progress across sessions and devices.

Full documentation, install options and changelog: <https://github.com/jame581/LogseqBrain>.

## Install

In Claude Code:

```
/plugin marketplace add jame581/skillsmith
/plugin install logseq-brain@skillsmith
```

## Setup

**Requirements:** a POSIX shell with `awk`. That is built into macOS, Linux and Cowork; on Windows, install [Git for Windows](https://git-scm.com/download/win) (Git Bash). The skills call a small bundled helper (`skills/_shared/bin/brain`) for every byte count, digest Map and format check. It reads and writes only inside your graph folder and makes no network calls.

Create a Logseq graph (e.g. "ClaudeBrain") and tell the plugin where it is. Pick one:

- **Environment variable**: `export LOGSEQ_BRAIN_PATH=/path/to/ClaudeBrain` (highest precedence)
- **Just tell Claude the path** when prompted. Claude saves it to a user config file (`%APPDATA%\logseq-brain\config.json` on Windows; otherwise `$XDG_CONFIG_HOME/logseq-brain/config.json` or `~/.config/logseq-brain/config.json`).

Then say **"init brain"** to set up the graph, and **"init brain project MyProject"** to add your first project.

## Skills

- **brain-init**: set up the graph, or add a project page ("init brain", "init brain project MyProject").
- **brain-load**: load a project's digest, about 2 KB however large the page is, and say what it didn't read ("load MyProject").
- **brain-save**: surgical appends of decisions, progress and plans, with a format check before anything is written ("save to brain"). Never saves without your confirmation.
- **brain-status**: dashboard of all projects and tasks ("brain status", "brain stats").
- **brain-doctor**: lint and, after a backup and your confirmation, repair graph format problems ("brain doctor").

## License

MIT, see [LICENSE](./LICENSE).
