# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code plugin (`logseq-brain`) that gives Claude persistent memory via a user-owned Logseq graph. There is **no build, no tests, no runtime code** — the plugin is entirely markdown skills (`skills/<name>/SKILL.md`) plus `.claude-plugin/plugin.json`. Claude itself is the runtime: skills instruct Claude to read/write markdown files in the user's `ClaudeBrain` graph using the standard Read/Write/Edit/Bash tools.

The `logseq-brain.plugin` file at repo root is a zip of the plugin for Cowork distribution. It's a **build artifact** — edit files under `skills/` and `.claude-plugin/`, not the `.plugin` archive.

## Architecture

Four skills make up the save/load cycle against a Logseq graph:

- **brain-init** — First-time graph setup (creates `pages/Index.md`, `Meta.md`, `Decisions.md`, `logseq/config.edn`, `journals/.gitkeep`) and adds new project pages.
- **brain-load** — Reads a project page back into the session. Supports brief/full modes, fuzzy project name matching, and cross-graph search ("what do we know about X").
- **brain-save** — Surgically appends session logs, decisions, plan updates to the relevant `Projects___<Name>.md` page via Edit. Also updates journals, Meta, Index. Detects cross-project decisions and decision conflicts (marks old as `status:: superseded`).
- **brain-status** — Dashboard across all project pages; flags stale projects.

### Graph path resolution (every skill does this)

Skills must resolve the ClaudeBrain folder in this order: Cowork directory → `LOGSEQ_BRAIN_PATH` env var → `.brain-config.json` (`{"graphPath": "..."}`) in plugin root → ask the user. Once resolved, all other brain skills depend on it.

### Logseq format invariants (non-negotiable when editing skills)

Skills generate content that must round-trip through Logseq's outliner without corruption:

- **Filenames use triple underscore `___` for namespace separators.** `pages/Projects___MyProject.md` renders as `Projects/MyProject` in Logseq.
- **All content must be bullet points.** No bare paragraphs. Logseq is an outliner; bare paragraphs get swallowed.
- **Properties use `key:: value` on bullet lines** (e.g. `status:: accepted`).
- **Page links use `[[Page Name]]` or `[[Namespace/Page Name]]`.**
- **Dates are always `yyyy-MM-dd`.** Journal filenames use underscores: `journals/yyyy_MM_dd.md`.
- **Writes are surgical** — use Edit to update specific sections, never rewrite whole pages. This minimizes Logseq Sync conflicts across devices (the whole point of the plugin is cross-device continuity).

### Save semantics worth knowing

- Never write session data to a non-existent project page — offer to create it via the brain-init flow first.
- Cross-project decisions are duplicated: written to the project page AND to `pages/Decisions.md` with a `projects::` list.
- Jira task entries in Current Plan store a **pointer** (task ID, folder path, summary) — the full plan/estimate lives in the external task folder, not the brain.
- Auto-save is a **suggestion only** — never persist without explicit user confirmation. This is a deliberate design decision.

## Working in this repo

- Edits almost always mean editing a `SKILL.md` frontmatter/body. The `description` field controls when Claude invokes the skill — change it carefully.
- There is nothing to run or test locally. Validation = use the skill against a real ClaudeBrain graph.
- `ROADMAP.md` is the source of truth for what's shipped vs. planned; current version is tracked in `.claude-plugin/plugin.json`.
