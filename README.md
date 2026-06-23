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
- "load MyProject" — loads the project context (brief mode by default)
- "load MyProject full" — loads everything including decisions, implementation, linked tasks
- "load brain" — loads a high-level overview of all projects
- "what do we know about strategy pattern" — searches across the graph

**brain-save** — Save the current session's work to the graph.
- "save to brain" — saves decisions, progress, and plans from this session
- "save progress" — same as above
- "remember this" — save specific information
- Automatically detects multi-project sessions and Jira task context
- Updates Meta.md when new user preferences are discovered

**brain-status** — Quick dashboard of all projects.
- "brain status" — shows all projects with status, last activity, current focus
- "show projects" — same as above
- Flags stale projects that haven't been updated recently

**brain-doctor** — Lint and repair the graph (graph hygiene).
- "brain doctor" / "check brain health" — scans for format problems and reports them
- "fix brain" / "clean up brain" — repairs them after a backup and your confirmation
- Catches the things that quietly create empty "phantom" pages or broken macros: code wrapped in `{{ }}`, bare `#number`/hex tags, un-namespaced `[[Task]]` links, `[[file://]]` links; also flags malformed properties, broken/duplicate entries, and structural gaps

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
