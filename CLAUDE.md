# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code plugin (`logseq-brain`) that gives Claude persistent memory via a user-owned Logseq graph. There is **no build, no tests, no runtime code** — the plugin is entirely markdown skills (`skills/<name>/SKILL.md`) plus `.claude-plugin/plugin.json`. Claude itself is the runtime: skills instruct Claude to read/write markdown files in the user's `ClaudeBrain` graph using the standard Read/Write/Edit/Bash tools.

**Target: Logseq OG (the markdown version) only.** Logseq split in 2026 — OG moved to <https://github.com/logseq/og> and is in maintenance mode (security and Electron upgrades, no new features), while the DB/SQLite version continues at the original repo. There is no API or CLI for file graphs (`@logseq/cli` serves DB graphs only), so all leverage here is file layout, property discipline, and ripgrep. Do not propose DB-version features.

The plugin is distributed via the [skillsmith](https://github.com/jame581/skillsmith) marketplace, the Gemini extension URL, and (for Cowork) a locally-built `logseq-brain.plugin` zip. The `.plugin` archive is a **build artifact** — gitignored (`*.plugin`), not checked in. Edit files under `skills/` and `.claude-plugin/`, never inside an archive.

## Architecture

Five skills make up the save/load cycle against a Logseq graph:

- **brain-init** — First-time graph setup (creates `pages/Index.md`, `Meta.md`, `Decisions.md`, `logseq/config.edn`, `journals/.gitkeep`) and adds new project pages. New project pages ship with a digest scaffold, so a fresh page never lands in a `missing-digest` report.
- **brain-load** — Reads a project page back into the session. Since v0.10.0 the default is **digest mode**: one `Read(offset 0, limit 20)` of the page-top properties + `## Digest`, then nothing else — everything further is fetched on demand through the escalation ladder, announced. A page with no digest falls back to the pre-v0.10.0 brief mode unchanged and is *offered* a digest, never given one uninvited. Also full mode, fuzzy project name matching, and cross-graph search ("what do we know about X").
- **brain-save** — Surgically appends session logs, decisions, plan updates to the relevant `Projects___<Name>.md` page via Edit. Also updates journals, Meta, Index. Detects cross-project decisions and decision conflicts (marks old as `status:: superseded`); seeds/updates task `status::`, suggests rotation of Session Logs past 64 KB/40 entries, refreshes the project's `Index.md` one-liner on every save, prompts on decision-shaped statements, and runs a mechanical post-write verify grep over the files it wrote. Since v0.10.0, step 9 of 13 **unconditionally refreshes the page's digest** — properties plus the `## Digest` section, with the Map bullet recomputed from the file rather than remembered.
- **brain-status** — Dashboard across all project pages, built from a **single ripgrep** over digest properties since v0.10.0; pages not yet backfilled fall back to section-targeted reads one page at a time. Flags stale projects; groups task pages by `status::`. Separate `brain-stats` analytics mode.
- **brain-doctor** — Graph-hygiene lint/repair (v0.8.0, extended in v0.9.0). Scans pages + journals for format violations that spawn phantom pages or broken macros (`{{ }}` mis-used for inline code, bare `#number`/hex tags, un-namespaced `[[Task]]` links, `[[file://]]` links, junk/description links), reports them, and — after a backup — repairs them. Includes the `jira-markup` residue check and the guided task-status backfill. v0.10.0 takes the rule catalog to **13** — adding `missing-digest`, `stale-digest` and `oversized-digest`, all report-tier — plus a guided whole-graph digest backfill ("backfill digests") that states its read cost before spending it. Maintenance tool, run on demand; not part of the per-session save/load cycle.

### Shared references (since v0.6.0)

Cross-skill logic lives under `skills/_shared/` — sibling to the skill folders, not inside any individual skill's `references/`. Each `SKILL.md` reads from `skills/_shared/<name>.md` on demand. This keeps `SKILL.md` orchestrators compact and avoids duplicating logic across skills.

Current shared references:

- `skills/_shared/path-resolution.md` — host-aware graph path resolution (Cowork vs. Claude Code/Copilot/Gemini)
- `skills/_shared/journey-log.md` — one-line activity-trail write logic, called by every brain skill
- `skills/_shared/staleness.md` — stale-project rules (used by `brain-load` and `brain-status`)
- `skills/_shared/section-locator.md` — grep-anchored section-targeted reads (used by `brain-load`, `brain-save`, `brain-status` to avoid full-page reads)
- `skills/_shared/logseq-format.md` — Logseq parse-time normalization behaviors + read-before-edit survival rules + compose-time content-generation invariants (used by brain-save, journey-log, brain-doctor; defers detection/remediation to hygiene-rules.md)
- `skills/_shared/hygiene-rules.md` — canonical graph-hygiene rule catalog (detection + remediation for all 13 issue classes; used by `brain-doctor` to scan and by `brain-save` to self-check)
- `skills/_shared/digest.md` — the digest contract: scope, the two surfaces, slot order, byte caps, the measured Map bullet, refresh vs. rebuild-from-source (used by `brain-load`, `brain-save`, `brain-doctor`, `brain-init`)
- `skills/_shared/escalation.md` — the 0–5 lazy-retrieval ladder used once a digest is loaded (used by `brain-load`)

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
- There is nothing to run or test locally. Validation = invoke the skill against a real ClaudeBrain graph (see `CONTRIBUTING.md` for the manual round-trip checklist).
- Current version is in `.claude-plugin/plugin.json`. `ROADMAP.md` lists shipped/current/future phases — verify shipped status by reading the skills, not the roadmap.
