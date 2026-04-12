# Logseq Brain

Persistent memory for Claude using a dedicated Logseq graph. Save and load project context, decisions, and progress across sessions and devices.

## Overview

This plugin turns a Logseq graph into Claude's external brain. Claude can read from and write to the graph, storing project plans, decisions, implementation details, and session logs. Because Logseq syncs across devices, your Claude context travels with you — start a task on your desktop, continue on your notebook.

## Setup

### Cowork (Desktop App)

1. Create a new Logseq graph called "ClaudeBrain" (or any name you prefer)
2. Install this plugin in Claude (accept the `.plugin` file)
3. Say "init brain" — Claude will ask you to select the graph folder
4. Say "init brain project Globus" to add your first project

### Claude Code / CLI

1. Create a new Logseq graph called "ClaudeBrain"
2. Install the plugin: `claude plugin add /path/to/logseq-brain`
3. Set the graph path (pick one):
   - Environment variable: `export LOGSEQ_BRAIN_PATH=/path/to/ClaudeBrain`
   - Config file: create `.brain-config.json` in the plugin root with `{"graphPath": "/path/to/ClaudeBrain"}`
   - Or just tell Claude the path when prompted
4. Say "init brain" to set up the graph structure

## Skills

**brain-init** — Set up the graph for the first time, or add a new project.
- "init brain" — creates the graph structure (Index, Meta, Decisions pages)
- "init brain project Globus" — adds a new project page

**brain-load** — Load project context into the current session.
- "load Globus" — loads the Globus project context
- "load brain" — loads a high-level overview of all projects
- "what do we know about strategy pattern" — searches across the graph

**brain-save** — Save the current session's work to the graph.
- "save to brain" — saves decisions, progress, and plans from this session
- "save progress" — same as above
- "remember this" — save specific information

## Graph Structure

```
ClaudeBrain/
├── pages/
│   ├── Index.md                    ← master index
│   ├── Meta.md                     ← your preferences and conventions
│   ├── Decisions.md                ← cross-project decisions
│   └── Projects___Globus.md        ← project pages (namespace: Projects/)
├── journals/
│   └── 2026_04_12.md    