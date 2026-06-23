# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code plugin (`logseq-brain`) that gives Claude persistent memory via a user-owned Logseq graph. There is **no build, no tests, no runtime code** — the plugin is entirely markdown skills (`skills/<name>/SKILL.md`) plus `.claude-plugin/plugin.json`. Claude itself is the runtime: skills instruct Claude to read/write markdown files in the user's `ClaudeBrain` graph using the standard Read/Write/Edit/Bash tools.

The plugin is distributed via the [skillsmith](https://github.com/jame581/skillsmith) marketplace, the Gemini extension URL, and (for Cowork) a locally-built `logseq-brain.plugin` zip. The `.plugin` archive is a **build artifact** — gitignored (`*.plugin`), not checked in. Edit files under `skills/` and `.claude-plugin/`, never inside an archive.

## Architecture

Five skills make up the save/load cycle against a Logseq graph:

- **brain-init** — First-time graph setup (creates `pages/Index.md`, `Meta.md`, `Decisions.md`, `logseq/config.edn`, `journals/.gitkeep`) and adds new project pages.
- **brain-load** — Reads a project page back into the session. Supports brief/full modes, fuzzy project name matching, and cross-graph search ("what do we know about X").
- **brain-save** — Surgically appends session logs, decisions, plan updates to the relevant `Projects___<Name>.md` page via Edit. Also updates journals, Meta, Index. Detects cross-project decisions and decision conflicts (marks old as `status:: superseded`).
- **brain-status** — Dashboard across all project pages; flags stale projects.
- **brain-doctor** — Graph-hygiene lint/repair (v0.8.0). Scans pages + journals for format violations that spawn phantom pages or broken macros (`{{ }}` mis-used for inline code, bare `#number`/hex tags, un-namespaced `[[Task]]` links, `[[file://]]` links, junk/description links), reports them, and — after a backup — repairs them. Maintenance tool, run on demand; not part of the per-session save/load cycle.

### Shared references (since v0.6.0)

Cross-skill logic lives under `skills/_shared/` — sibling to the skill folders, not inside any individual skill's `references/`. Each `SKILL.md` reads from `skills/_shared/<name>.md` on demand. This keeps `SKILL.md` orchestrators compact and avoids duplicating logic across skills.

Current shared references:

- `skills/_shared/path-resolution.md` — host-aware graph path resolution (Cowork vs. Claude Code/Copilot/Gemini)
- `skills/_shared/journey-log.md` — one-line activity-trail write logic, called by every brain skill
- `skills/_shared/staleness.md` — stale-project rules (used by `brain-load` and `brain-status`)
- `skills/_shared/section-locator.md` — grep-anchored section-targeted reads (used by `brain-load`, `brain-save`, `brain-status` to avoid full-page reads)
- `skills/_shared/logseq-format.md` — Logseq parse-time normalization behaviors + read-before-edit survival rules + compose-time content-generation invariants (used by brain-save, journey-log, brain-doctor; defers detection/remediation to hygiene-rules.md)
- `skills/_shared/hygiene-rules.md` — canonical graph-hygiene rule catalog (detection + remediation for all 9 issue classes; used by `brain-doctor` to scan and by `brain-save` to self-check)

When adding a new shared reference, prefer this directory. Per-skill references stay in `skills/<skill>/references/`.

### Graph path resolution (every skill does this)

See `skills/_shared/path-resolution.md` — branches by host (Cowork uses `request_cowork_directory`; Claude Code / Copilot CLI / Gemini CLI use `LOGSEQ_BRAIN_PATH` env var → durable user config file at `%APPDATA%\logseq-brain\config.json` / `~/.config/logseq-brain/config.json` → ask-and-persist). The config file lives outside the plugin cache so it survives `/reload-plugins`. Once resolved, all other brain operations in the session use that path. When editing skills, preserve this host-aware branching — don't collapse it into a single chain.

### Logseq format invariants (non-negotiable when editing skills)

Skills generate content that must round-trip through Logseq's outliner without corruption:

- **Filenames use triple underscore `___` for namespace separators.** `pages/Projects___MyProject.md` renders as `Projects/MyProject` in Logseq.
- **All content must be bullet points.** No bare paragraphs. Logseq is an outliner; bare paragraphs get swallowed.
- **Properties use `key:: value` on bullet lines** (e.g. `status:: accepted`).
- **Page links use `[[Page Name]]` or `[[Namespace/Page Name]]`** — and links to task/project pages must be **namespaced** (`[[Tasks/CRMGM-1234]]`, not bare `[[CRMGM-1234]]`), or they create a phantom duplicate page.
- **Inline code uses backticks, NEVER `{{ }}`.** `{{ }}` is Logseq *macro* syntax; with the default `:macros {}` it renders broken. Code, identifiers, file:line refs, CSS, and DB queries get backticks.
- **Escape `#` before a number or hex color** (PR `#44`, `#0066CC`) — a bare `#44` becomes a tag → an empty phantom page. Real tags use `#[[Page Name]]`.
- **Local file paths are markdown links `[label](file:///…)` or backticks — never `[[file://]]`** (which makes a phantom page titled with the path).
- **Dates are always `yyyy-MM-dd`.** Journal filenames use underscores: `journals/yyyy_MM_dd.md`.
- **Writes are surgical** — use Edit to update specific sections, never rewrite whole pages. This minimizes Logseq Sync conflicts across devices (the whole point of the plugin is cross-device continuity).

The compose-time rules (backticks, `#`-escaping, namespaced links, file links) are documented in full in `skills/_shared/logseq-format.md` and enforced reactively by the `brain-doctor` skill.

### Save semantics worth knowing

- Never write session data to a non-existent project page — offer to create it via the brain-init flow first.
- Cross-project decisions are duplicated: written to the project page AND to `pages/Decisions.md` with a `projects::` list.
- Jira task entries in Current Plan store a **pointer** (task ID, folder path, summary) — the full plan/estimate lives in the external task folder, not the brain.
- Auto-save is a **suggestion only** — never persist without explicit user confirmation. This is a deliberate design decision.

## Working in this repo

- Edits almost always mean editing a `SKILL.md` frontmatter/body. The `description` field controls when Claude invokes the skill — change it carefully.
- There is nothing to run or test locally. Validation = invoke the skill against a real ClaudeBrain graph (see `CONTRIBUTING.md` for the manual round-trip checklist).
- Current version is in `.claude-plugin/plugin.json`. `ROADMAP.md` lists shipped/current/future phases — verify shipped status by reading the skills, not the roadmap.
