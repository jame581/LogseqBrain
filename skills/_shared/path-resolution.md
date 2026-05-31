# Graph Path Resolution

All four brain skills (`brain-init`, `brain-load`, `brain-save`, `brain-status`) need to resolve the user's ClaudeBrain Logseq graph folder before doing anything else. Resolution branches by host.

## Resolution order

### In Cowork (desktop app)

If no folder is currently connected, call `request_cowork_directory` to ask the user to select their ClaudeBrain graph folder. Store the resolved path for the session.

### In Claude Code / GitHub Copilot CLI / Gemini CLI

Try in this order; stop at the first success:

1. **Argument:** the user provided a path inline (e.g., "load brain at /path/to/graph"). Use it directly.
2. **Environment variable:** read `LOGSEQ_BRAIN_PATH`. If set and non-empty and the path exists, use it. When the env var wins, don't read or write the config file **for path resolution** — but note this is only about the graph path; other skills may still read the same config file for non-path settings (e.g. the `journeyLog` toggle, per `skills/_shared/journey-log.md`).
3. **User config file:** read `graphPath` from the durable user config file (see "Config file location" below). If the `graphPath` key is present and the path exists, use it.
4. **One-time legacy migration:** if no user config file exists yet, check for a legacy `.brain-config.json` at the plugin root. If found, valid, **and its `graphPath` exists on disk**, copy all its keys into the user config file (creating the directory if needed) (see "Config file location"), then use its `graphPath`. Silent best-effort — if the legacy file is missing/invalid **or its path no longer exists**, don't migrate a dead path; fall through to step 5.
5. **Ask the user.** Prompt: "Where is your ClaudeBrain Logseq graph folder?" After they answer and the path is confirmed to exist, **persist** it to the user config file (creating the directory if needed).

Once resolved, all other brain operations in this session use that path.

## Config file location

The durable user config file lives **outside the plugin cache** so it survives `/reload-plugins` and version bumps:

- **Windows:** `%APPDATA%\logseq-brain\config.json`
- **macOS / Linux:** `$XDG_CONFIG_HOME/logseq-brain/config.json` if `XDG_CONFIG_HOME` is set, otherwise `~/.config/logseq-brain/config.json`

Create the `logseq-brain` directory if it does not exist when persisting. Read with the Read tool; write with the Write tool.

> **Legacy:** older versions stored `.brain-config.json` at the plugin cache root. That file is wiped on reload, so it is now only a one-time migration source (resolution step 4, which copies all its keys to the new location), never the source of truth.

## Config file shape

```json
{
  "graphPath": "/absolute/path/to/ClaudeBrain",
  "journeyLog": true
}
```

- `graphPath` (string, required for non-Cowork hosts): absolute path to the graph folder.
- `journeyLog` (boolean, optional, default `true`): whether to write activity-trail entries on each brain skill use. See `skills/_shared/journey-log.md`.

## Failure modes

- **Path doesn't exist:** tell the user the path is invalid and ask for a correct one. Don't try to create the folder — that's `brain-init`'s job once the path is confirmed.
- **Empty folder:** that's not a path-resolution failure; it's a signal that `brain-init` first-time setup is needed. Hand off to `brain-init` if the user wasn't already running it.
- **Conflicting config + env:** the `LOGSEQ_BRAIN_PATH` env var wins **for the graph path**, and the config file's `graphPath` is not consulted (per the resolution order above). This scoping is path-only: non-path settings such as the `journeyLog` toggle are still read from the config file by `skills/_shared/journey-log.md`, even when the env var supplied the path.
- **Config directory not writable:** if persisting to the user config file fails, tell the user the path was resolved for this session but could not be saved, and suggest setting `LOGSEQ_BRAIN_PATH`. Don't block the operation.
