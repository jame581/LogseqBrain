# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code plugin (`logseq-brain`) that gives Claude persistent memory via a user-owned Logseq graph. The plugin is markdown skills (`skills/<name>/SKILL.md`), `.claude-plugin/plugin.json`, and, since v0.11.0, **one POSIX `sh` + `awk` helper**: `skills/_shared/bin/brain` plus `skills/_shared/lib/*.awk`. Claude does the judgment (what to save, the prose). The helper does every mechanical step: section measurement, the digest Map, caps, scoped search, lint, the activity line. This deliberately reverses the earlier "no runtime code" rule, within a narrow boundary: POSIX sh/awk only, no new dependencies, and the script writes only the Map line and the activity line (`docs/superpowers/specs/2026-09-11-v0.11.0-design.md`).

**Target: Logseq OG (the markdown version) only.** Logseq split in 2026 — OG moved to <https://github.com/logseq/og> and is in maintenance mode (security and Electron upgrades, no new features), while the DB/SQLite version continues at the original repo. There is no API or CLI for file graphs (`@logseq/cli` serves DB graphs only), so all leverage here is file layout, property discipline, and ripgrep. Do not propose DB-version features.

The plugin is distributed via the [skillsmith](https://github.com/jame581/skillsmith) marketplace, the Gemini extension URL, and (for Cowork) a locally-built `logseq-brain.plugin` zip. The `.plugin` archive is a **build artifact** — gitignored (`*.plugin`), not checked in. Edit files under `skills/` and `.claude-plugin/`, never inside an archive. Rebuild it from committed content after every release — `git archive --format=zip -o logseq-brain.plugin HEAD .claude-plugin skills README.md` — nothing else keeps it current, and a stale one silently ships old skills to Cowork.

## Architecture

Five skills make up the save/load cycle against a Logseq graph: `brain-init` (setup / new project pages), `brain-load` (read a page back), `brain-save` (surgical appends), `brain-status` (dashboard + `brain-stats`), `brain-doctor` (hygiene lint/repair, on demand only). Read each `skills/<name>/SKILL.md` for current behavior — don't rely on a summary here.

### Shared references (since v0.6.0)

Cross-skill logic lives under `skills/_shared/` — sibling to the skill folders, not inside any individual skill's `references/`. Each `SKILL.md` reads from `skills/_shared/<name>.md` on demand. This keeps `SKILL.md` orchestrators compact and avoids duplicating logic across skills. One of these is still large — `hygiene-rules.md` (18 KB) — so grep to the relevant rule rather than reading it whole.

When adding a new shared reference, prefer this directory. Per-skill references stay in `skills/<skill>/references/`.

### The helper (since v0.11.0)

`skills/_shared/bin/brain` is a sh dispatcher. Each command is an awk program loaded after `lib/core.awk` (`awk -f core.awk -f <prog>.awk`). Skills invoke it as described in `skills/_shared/run-brain.md`: via `sh`, or via Git's `bash.exe` on PowerShell-only Windows hosts. It is required, and there is no prose fallback. Portability rules are non-negotiable: `LC_ALL=C` (lengths are bytes), POSIX awk only (no `gensub`, three-argument `match`, `strftime`/`mktime`, `{n,m}` intervals, or `length(array)`), and graph-relative paths in output. Its only writes are the Map line (`digest --apply`) and one activity bullet (`activity`). Both are verified to touch only those lines before an in-place commit.

### Design docs

Each minor version gets a design spec in `docs/superpowers/specs/` and an implementation plan in `docs/superpowers/plans/`, both dated `yyyy-MM-dd`. After launch, corrections are **annotated into** the spec (`Post-launch correction (wave A, <date>)`), never rewritten over — the spec stays an honest record of what shipped vs. what was fixed after. Plans are left frozen. (`.superpowers/` at the repo root is gitignored subagent scratch — not this.)

### Graph path resolution (every skill does this)

See `skills/_shared/path-resolution.md`. When editing skills, preserve this host-aware branching — don't collapse it into a single chain.

### Logseq format invariants (non-negotiable when editing skills)

Skills generate content that must round-trip through Logseq's outliner without corruption:

- **Filenames use triple underscore `___` for namespace separators.** `pages/Projects___MyProject.md` renders as `Projects/MyProject` in Logseq.
- **All content must be bullet points.** No bare paragraphs. Logseq is an outliner; bare paragraphs get swallowed.
- **Properties use `key:: value` on bullet lines** (e.g. `status:: accepted`).
- **Page links use `[[Page Name]]` or `[[Namespace/Page Name]]`** — and links to task/project pages must be **namespaced** (`[[Tasks/CRMGM-1234]]`, not bare `[[CRMGM-1234]]`), or they create a phantom duplicate page.
- **Inline code uses backticks, NEVER `{{ }}`.** `{{ }}` is Logseq *macro* syntax; with the default `:macros {}` it renders broken. Code, identifiers, file:line refs, CSS, and DB queries get backticks.
- **Escape `#` before a number or hex color** (PR `#44`, `#0066CC`) — a bare `#44` becomes a tag → an empty phantom page. Real tags use `#[[Page Name]]` — and never put `#` directly before non-space text even after a letter: `C#-parity` makes a page `-parity`, `PKCS#12` a page `12` (measured against Logseq's parse cache, 2026-09-11).
- **Local file paths are markdown links `[label](file:///…)` or backticks — never `[[file://]]`** (which makes a phantom page titled with the path).
- **Foreign markup (Jira etc.) never goes raw into bullets — store drafts verbatim in fenced code blocks.**
- **Dates are always `yyyy-MM-dd`.** Journal filenames use underscores: `journals/yyyy_MM_dd.md`.
- **Writes are surgical** — use Edit to update specific sections, never rewrite whole pages. This minimizes Logseq Sync conflicts across devices (the whole point of the plugin is cross-device continuity).
- **Project and task pages carry a digest** — page-top `focus::` / `next::` / `open::` / `digest-updated::` plus a `## Digest` section capped at **800 bytes**, whose last bullet is a **measured** map of the page. `brain-load` reads only this; `brain-save` refreshes it on every save. Full contract in `skills/_shared/digest.md`. Never author the map from memory — compute it.
- **Partial reads must state their coverage.** Any bounded read says what it left out (`read 4 KB of 89 KB of ## Session Log`). Silent truncation is what lets the model reason from a fragment. See `skills/_shared/section-locator.md`.

The compose-time rules (backticks, `#`-escaping, namespaced links, file links) are documented in full in `skills/_shared/logseq-format.md` and enforced reactively by the `brain-doctor` skill.

### Save semantics worth knowing

- Never write session data to a non-existent project page — offer to create it via the brain-init flow first.
- Cross-project decisions are duplicated: written to the project page AND to `pages/Decisions.md` with a `projects::` list.
- Jira task entries in Current Plan store a **pointer** (task ID, folder path, summary) — the full plan/estimate lives in the external task folder, not the brain.
- Auto-save is a **suggestion only** — never persist without explicit user confirmation. This is a deliberate design decision.

## Working in this repo

- Edits almost always mean editing a `SKILL.md` frontmatter/body. The `description` field controls when Claude invokes the skill — change it carefully.
- Run `sh tests/run.sh` after any change to `skills/_shared/bin/` or `lib/`. CI runs it on mawk, BWK awk and gawk. Skill prose is still validated by the manual round-trip in `CONTRIBUTING.md`. Before changing a lint rule, run `python tools/oracle/oracle.py --graph <graph>`: detection is validated against Logseq's own parse cache. `tools/` is dev-only and never shipped.
- Current version is in `.claude-plugin/plugin.json`. `ROADMAP.md` lists shipped/current/future phases — verify shipped status by reading the skills, not the roadmap.
- **One branch per minor version.** Work happens on a `vX.Y.Z` branch merged to `main` by PR (#1–#4 all did); commits are conventional with a scope — `feat(brain-init):`, `fix(digest):`, `docs(claude-md):`.
- **Releasing touches two repos.** Bumping `.claude-plugin/plugin.json`, tagging, and cutting the GitHub release is only half — new installs don't move until `.claude-plugin/marketplace.json` in the separate [`skillsmith`](https://github.com/jame581/skillsmith) repo is bumped too. Full steps: `CONTRIBUTING.md` § Releasing a new version.
