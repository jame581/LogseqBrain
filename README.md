# Logseq Brain

[![Version](https://img.shields.io/github/v/tag/jame581/LogseqBrain?label=version&color=blue)](https://github.com/jame581/LogseqBrain/releases)
[![License](https://img.shields.io/github/license/jame581/LogseqBrain?color=green)](./LICENSE)
[![Skillsmith](https://img.shields.io/badge/marketplace-skillsmith-8A2BE2)](https://github.com/jame581/skillsmith)

Persistent memory for Claude using a dedicated [Logseq](https://logseq.com) graph. Save and load project context, decisions, and progress across sessions and devices.

## Overview

This plugin turns a Logseq graph into Claude's external brain. Claude can read from and write to the graph, storing project plans, decisions, implementation details, and session logs. Because Logseq syncs across devices, your Claude context travels with you — start a task on your desktop, continue on your notebook.

## Install

Logseq Brain ships through the [**skillsmith**](https://github.com/jame581/skillsmith) marketplace.

### Claude Code

```
/plugin marketplace add jame581/skillsmith
/plugin install logseq-brain@skillsmith
```

### GitHub Copilot CLI

```
copilot plugin marketplace add jame581/skillsmith
copilot plugin install logseq-brain@skillsmith
```

### Gemini CLI

```
gemini extensions install https://github.com/jame581/LogseqBrain
```

### Cowork (Desktop App)

1. Create a new Logseq graph called "ClaudeBrain" (or any name you prefer).
2. Install this plugin in Claude (accept the `.plugin` file).
3. Say "init brain" — Claude will ask you to select the graph folder.
4. Say "init brain project MyProject" to add your first project.

## Setup

After installing, create a Logseq graph (e.g. "ClaudeBrain") and tell the plugin where to find it. Pick one:

- **Environment variable**: `export LOGSEQ_BRAIN_PATH=/path/to/ClaudeBrain` (highest precedence)
- **Just tell Claude the path** when prompted — Claude saves it to a durable user config file (`%APPDATA%\logseq-brain\config.json` on Windows; on macOS/Linux `$XDG_CONFIG_HOME/logseq-brain/config.json` if `XDG_CONFIG_HOME` is set, otherwise `~/.config/logseq-brain/config.json`) so you're not asked again, even after plugin reloads

Then say **"init brain"** to set up the graph structure, and **"init brain project MyProject"** to add your first project.

## Skills

**brain-init** — Set up the graph for the first time, or add a new project.
- "init brain" — creates the graph structure (Index, Meta, Decisions pages)
- "init brain project MyProject" — adds a new project page

**brain-load** — Load project context into the current session.
- "load MyProject" — loads the project's **digest**: one read, under ~2 KB no matter how big the page is, and it tells you exactly what it *didn't* read
- Anything it didn't read is one question away — ask and it greps for just that, announcing each step
- "load MyProject full" — loads everything including decisions, implementation, linked tasks
- "load brain" — loads a high-level overview of all projects
- "what do we know about strategy pattern" — searches across the graph

**brain-save** — Save the current session's work to the graph.
- "save to brain" — saves decisions, progress, and plans from this session
- "save progress" — same as above
- "remember this" — save specific information
- Automatically detects multi-project sessions and Jira task context
- Updates Meta.md when new user preferences are discovered
- Jira comment drafts are stored verbatim in fenced code blocks, then verified with a mechanical post-write check over the files just written
- Seeds and updates task `status::` as work progresses, and suggests Session Log rotation to a `SessionArchive` page once a project page grows past 64 KB / 40 entries
- Refreshes the project's `Index.md` one-liner on every save
- Refreshes the page's digest on every save, so the cheap-recall surface never goes stale

**brain-status** — Quick dashboard of all projects.
- "brain status" — shows all projects with status, last activity, current focus
- "show projects" — same as above
- Flags stale projects that haven't been updated recently
- Groups task pages by `status::` (active, blocked, done)
- Builds the whole dashboard from a single search across digest properties

**brain-doctor** — Lint and repair the graph (graph hygiene).
- "brain doctor" / "check brain health" — scans for format problems and reports them
- "fix brain" / "clean up brain" — repairs them after a backup and your confirmation
- Catches the things that quietly create empty "phantom" pages or broken macros: code wrapped in `{{ }}`, bare `#number`/hex tags, un-namespaced `[[Task]]` links, `[[file://]]` links; also flags malformed properties, broken/duplicate entries, and structural gaps
- Reports unfenced Jira markup residue and guides a one-time batch backfill of missing task `status::`
- Reports pages with a missing, stale, or oversized digest, and can backfill them in one guided pass ("backfill digests")

## Graph Structure

```
ClaudeBrain/
├── pages/
│   ├── Index.md                    ← master index
│   ├── Meta.md                     ← your preferences and conventions
│   ├── Decisions.md                ← cross-project decisions
│   └── Projects___MyProject.md     ← project pages (namespace: Projects/)
├── journals/
│   └── 2026_04_12.md                ← daily journal: ## Sessions + ## Activity
└── logseq/
    └── config.edn                   ← Logseq graph config
```

## Journey Log

Every brain operation (init / load / save / status / search) leaves a one-line `HH:mm`-prefixed bullet in today's journal under `## Activity` — a low-cost, time-ordered audit trail of what Claude did, when. Disable by adding `"journeyLog": false` to your user config file (`%APPDATA%\logseq-brain\config.json` on Windows; on macOS/Linux `$XDG_CONFIG_HOME/logseq-brain/config.json` if `XDG_CONFIG_HOME` is set, otherwise `~/.config/logseq-brain/config.json`).

## Digest

Every project and task page carries a small summary at the top — four properties (`focus::`, `next::`, `open::`, `digest-updated::`) and a `## Digest` section capped at 800 bytes. Loading a project reads *only* that, so a 107 KB page costs under 2 KB instead of reading it whole.

The last digest bullet is a **map** — e.g. `Session Log | 87 KB (47 entries) · Active Tasks | 10 KB · Current Plan | 3 KB · Decisions | 2 KB (2) · page | 107 KB` — computed from the file, never written from memory, and derived from whatever sections the page actually has (not a fixed list — a page whose real second-largest section is `Active Tasks` shows `Active Tasks`). It does two jobs: it tells Claude what it doesn't have (so it can't quietly reason as though it read everything), and it's the index Claude uses when you ask for more.

Pages without a digest keep working exactly as before, and get one the first time you load or save them. Run `brain-doctor` and say "backfill digests" to do the whole graph at once.
