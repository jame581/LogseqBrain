# Graph Path Resolution

Every brain skill needs the user's ClaudeBrain graph folder. The helper (`skills/_shared/run-brain.md`) resolves it by itself: `--graph`, then `LOGSEQ_BRAIN_PATH`, then `graphPath` in the config file below. The environment variable wins over the config file. `brain info` prints the result (`graph:`, `graph-source:`). When none of these points at an existing folder, the helper exits 2 with `graph not resolved`. The skill then resolves the path as below, and passes it to every call as `--graph`.

## When the helper can't resolve it

- **Cowork (desktop app):** if no folder is connected, call `request_cowork_directory`. Always pass the connected folder as `--graph`.
- **Claude Code / Copilot CLI / Gemini CLI:** stop at the first success.
  1. **Argument:** the user gave a path inline ("load brain at /path/to/graph").
  2. **One-time legacy migration:** if no user config file exists, but a legacy `.brain-config.json` at the plugin root has a `graphPath` that exists on disk, copy all its keys into the user config file (creating the directory). This is silent and best-effort; never migrate a dead path.
  3. **Ask:** "Where is your ClaudeBrain Logseq graph folder?" Once the path is confirmed to exist, **persist** it as `graphPath` in the user config file (creating the directory).

## Config file

It lives outside the plugin cache, so it survives `/reload-plugins` and version bumps:
- **Windows:** `%APPDATA%\logseq-brain\config.json`
- **macOS / Linux:** `$XDG_CONFIG_HOME/logseq-brain/config.json`, else `~/.config/logseq-brain/config.json`

```json
{ "graphPath": "/absolute/path/to/ClaudeBrain", "journeyLog": true }
```

- `graphPath`: the absolute path to the graph folder (required outside Cowork).
- `journeyLog` (optional, default `true`): whether `brain activity` writes the activity trail. It is read from this file even when `LOGSEQ_BRAIN_PATH` supplied the path.

## Failure modes

- **The path doesn't exist:** say so and ask for a correct one. Don't create the folder; that is `brain-init`'s job once the path is confirmed.
- **Empty folder:** not a resolution failure. Hand off to `brain-init` for first-time setup.
- **Config directory not writable:** the path works for this session but couldn't be saved. Suggest setting `LOGSEQ_BRAIN_PATH`, and don't block the operation.
