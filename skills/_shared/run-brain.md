# Running the brain helper

Every brain skill does its mechanical work with one POSIX `sh` script rather than improvised shell: measuring sections, the digest Map and caps, scoped search, format lint, the journey-log line. The script is exact where hand arithmetic drifts, and one call replaces several.

## How to call it

The script is `skills/_shared/bin/brain`, which is `<this skill's base directory>/../_shared/bin/brain`. Always run it through `sh`, never directly:

- **Bash-capable host** (Claude Code, Cowork, Gemini or Copilot CLI): `sh "<path>/brain" <command> …` with the Bash tool.
- **PowerShell-only host on Windows:** `& "$(Split-Path (Split-Path (Get-Command git).Source))\bin\bash.exe" "<path>/brain" <command> …`
- **Neither works:** stop and tell the user *"logseq-brain needs Git for Windows (Git Bash) — https://git-scm.com/download/win"*. There is no prose fallback.

## The graph

The script resolves the graph itself: `--graph DIR`, then `LOGSEQ_BRAIN_PATH`, then `graphPath` in the user config file. **Run `brain info` once at the start of every skill run.** Its `graph:` line is the folder to use for every Read, Edit and Write the skill makes itself, and its `graph-source:` line says where that came from. In Cowork, always pass `--graph <connected folder>`. If it exits 2 with `graph not resolved`, follow the ask-and-persist steps in `skills/_shared/path-resolution.md`, then pass `--graph` to every call.

## Commands

| Command | Use it for |
|---|---|
| `info` | Once per skill run: `graph:` (the folder for your own Read/Edit/Write), `graph-source:`, the version and the awk in use |
| `digest <page>` | Load: the property block, the whole `## Digest`, and `map:` / `digest:` / `drift:` / `staleness:` / `coverage:` lines. With no digest: the section table instead. |
| `digest <page> --apply` | Save, rotation, doctor: rewrite **only** the Map line from measurement, then report caps and lint. Never hand-edit the Map line. |
| `journal <page> [--date d]` | That page's mentions in a journal, shrunk to ~2 KB, with coverage |
| `sections <page> [--baseline FILE…]` | Section sizes, and baselines for `check`. Call it before a save's first Edit, naming every file the save will touch. |
| `read <page> "<section>" [--max B]` | A whole section, if it is under the cap (default 8 KB) |
| `tail <page> "<section>" [--entries N] [--max B]` | The newest dated entries, byte-bounded, never zero |
| `search "<term>" [--page P] [--section S] [--context N]` | Counts first. Hits only when there are ≤ 20 and they fit in 4 KB; context windows only up to 8 KB. Never searches `logseq/`. |
| `check <file…>` | After writing: lint only what you added since the baseline |
| `lint [--all \| files…]` | Every rule over whole files (brain-doctor) |
| `status` | One TSV row per project and task page (brain-status) |
| `activity "<line>"` | The journey-log line in today's journal (`HH:MM` added for you) |

## Reading its output

- One fact per line; paths are graph-relative.
- Commands that return content end with a `coverage:` line. **Quote it** when you present the content: it is your truncation-honesty statement.
- Exit **0** clean · **1** findings (read and act on them) · **2** usage or environment error (a one-line reason on stderr: act on it, don't retry blindly).
- **Never recompute what it printed.** Its figures are the figures.
