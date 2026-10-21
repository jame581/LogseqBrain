# The brain helper — command reference

A routine load or save does **not** need this file: every SKILL.md carries the invocation block, and brain-load and brain-save name the commands they use. Read it for a rare command, or as a maintainer.

Every brain skill does its mechanical work with one POSIX `sh` script, rather than improvised shell: measuring sections, the digest Map and caps, scoped search, format lint, the journey-log line. The script is exact where hand arithmetic drifts, and one call replaces several.

## How to call it

The script is `<this skill's base directory>/../_shared/bin/brain`. Always run it through `sh`, never directly:

- **Bash-capable host** (Claude Code, Cowork, Gemini or Copilot CLI): `sh "<path>/brain" <command> …` with the Bash tool.
- **PowerShell-only host on Windows:** `& "$(Split-Path (Split-Path (Get-Command git).Source))\bin\bash.exe" "<path>/brain" <command> …`. This assumes `git` resolves to `Git\cmd\git.exe`, the Git for Windows default.
- **Neither works:** stop and tell the user *"logseq-brain needs Git for Windows (Git Bash) — https://git-scm.com/download/win"*. There is no prose fallback.

**Quote text arguments in single quotes.** Inside double quotes the shell runs backticks and expands `$` before the helper sees the text, so a summary like ``fixed `a` for $HOME`` would arrive mangled. A `'` inside the text becomes `'\''`.

## The graph

The script resolves the graph itself: `--graph DIR`, then `LOGSEQ_BRAIN_PATH`, then `graphPath` in the user config file.
- **`--graph` may appear anywhere** on the line, before or after the command and its arguments. `--graph` given twice, or with an empty value, is an error (exit 2).
- `--` ends flag parsing: `brain search -- '--graph'` searches for the literal text.
- `brain info` prints `graph:` (the folder for your own Read, Edit and Write calls) and `graph-source:`. The composites print the same lines under `== info`.
- In Cowork, always pass `--graph <connected folder>`.
- On exit 2 with `graph not resolved`, follow `skills/_shared/path-resolution.md`, then pass `--graph` to every call.

## Commands

| Command | Use it for |
|---|---|
| `load <page> [--mode digest\|full]` | A load in one call: `info`, the digest, today's journal mentions, and the `(digest)` activity line when the page has a digest. `--mode full`: the section table and a `full-budget:` line instead, and no activity line. |
| `save-begin <page> [--also FILE…]` | The start of a save: baselines for the page, `pages/Index.md`, today's journal and each `--also` file; the digest; the newest Session Log entry; Current Plan; the Edit anchors (`index:`, `sessions:`). It writes a per-page manifest. **A rerun resets the baselines**, so run it once, before the first Edit. |
| `save-finish <page> [--summary T] [--index T]` | The end of a save. It validates first and writes nothing on a refusal: the texts, the caps, and a dry-run Map on every digest-bearing page in the manifest. Then it writes the `## Sessions` bullet and the Index parenthetical, applies each Map, and checks every baselined file. Last comes the activity line, deferred while a new error-tier finding stands. |
| `info` | `graph:`, `graph-source:`, the version and the awk in use |
| `digest <page>` | The property block, the whole `## Digest`, and the `map:` / `digest:` / `drift:` / `staleness:` / `coverage:` lines. With no digest: the section table instead. |
| `digest <page> --apply` | Rotation, doctor, init: rewrite **only** the Map line from measurement, then report caps and lint. Never hand-edit the Map line. |
| `journal <page> [--date d]` | That page's mentions in a journal, shrunk to ~2 KB, with coverage |
| `sections <page> [--baseline FILE…]` | Section sizes, plus baselines for `check`. **Side effect:** it (re)saves the baselines `check` diffs against. |
| `read <page> '<section>' [--max B]` | A whole section, if it is under the cap (default 8 KB). `'X'`, `'## X'` and `'- ## X'` name the same section. |
| `tail <page> '<section>' [--entries N] [--max B]` | The newest dated entries, byte-bounded, never zero |
| `search '<term>' [--page P] [--section S] [--context N]` | Counts first. Hits only when there are ≤ 20 and they fit in 4 KB; context windows only up to 8 KB. Never searches `logseq/`. |
| `check <file…>` | After writing: lint only what was added since the baseline, with a `fix <rule>:` hint per rule that fired |
| `lint [--all \| files…]` | Every rule over whole files (brain-doctor) |
| `status` | One TSV row per project and task page (brain-status) |
| `activity '<line>'` | The journey-log line in today's journal (`HH:MM` added for you) |

## Reading its output

- One fact per line; paths are graph-relative.
- A composite's output is its parts' output, each headed by a `== <name>` line.
- Commands that return content end with a `coverage:` line. **Quote it** when you present the content: it is your truncation-honesty statement.
- Exit **0** clean · **1** findings (read and act on them) · **2** usage or environment error (a one-line reason on stderr: act on it, don't retry blindly). A composite exits with the worst of its parts.
- **Never recompute what it printed.** Its figures are the figures.
