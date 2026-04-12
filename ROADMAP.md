# Logseq Brain — Roadmap

## Current State: MVP (v0.1.0)

Three skills shipped: `brain-init`, `brain-load`, `brain-save`.
Graph initialized, repo pushed to GitHub.
Save/load cycle tested and working.

---

## Phase 1: Harden the MVP (v0.2.0)

Fix gaps found during testing and make the existing skills more robust.

### 1.1 Fix journals/ directory creation in brain-init
- brain-init says it creates the `journals/` dir but doesn't actually do it
- Should create the directory during first-time graph setup

### 1.2 Guard against missing project pages in brain-save
- If user says "save to brain" but no project page exists, brain-save should either:
  - Offer to create one (call brain-init flow)
  - Or clearly tell the user to init the project first
- Currently would fail silently or write to a broken location

### 1.3 Fuzzy project matching in brain-load
- "load logseq brain" should match `Projects___LogseqBrain.md`
- Case-insensitive matching, handle spaces vs camelCase vs kebab-case
- List available projects if no match found, let user pick

### 1.4 Validate Logseq format compliance
- Ensure all writes produce valid Logseq outliner format
- All content must be in bullet points (not bare paragraphs)
- Properties must use `key:: value` on bullet lines
- Links must use `[[Page Name]]` syntax

### 1.5 Handle Logseq Sync safety
- Don't write while Logseq is actively syncing (warn the user)
- Use atomic-ish writes (write to temp, then move) where possible

---

## Phase 2: Richer Context (v0.3.0)

Make brain-load smarter and brain-save more comprehensive.

### 2.1 Cross-project search ("what do we know about X")
- Grep across all .md files in the graph for a search term
- Present findings with links to source pages
- brain-load skill already describes this but implementation needs to be solid

### 2.2 Smart context budgeting in brain-load
- When loading a project, estimate token count of each section
- Prioritize: Current Plan > recent Session Log > Decisions > Implementation > Overview
- Allow user to say "load [project] full" vs "load [project] brief"

### 2.3 Richer session log entries
- Track which files were modified during a session
- Track which tools/skills were used
- Include links to related Jira tickets if applicable

### 2.4 Meta page auto-population
- As Claude learns user preferences across sessions, write them to Meta.md
- Working style, preferred formats, tool preferences
- This becomes a "user manual" for Claude across all projects

---

## Phase 3: Multi-Project & Integration (v0.4.0)

Connect the brain to existing workflows.

### 3.1 External task skill integration
- When a task management skill creates a plan/estimate for a Jira ticket, auto-save to the project's brain page
- When brain-load loads a project, include active Jira task context
- Bridge between task-level work and project-level knowledge

### 3.2 Multi-project session support
- Support sessions that span multiple projects
- brain-save should detect which projects were discussed and write to each
- brain-load should allow loading multiple projects: "load ProjectA and ProjectB"

### 3.3 Cross-project decision log
- Decisions that affect multiple projects go to `pages/Decisions.md`
- brain-save should detect cross-cutting decisions and write to both the project page and the global log

### 3.4 Project status dashboard
- "brain status" command — shows all projects with status, last activity, active blockers
- Quick way to see the big picture without loading everything

---

## Phase 4: Intelligence Layer (v0.5.0)

Make the brain proactive and smarter.

### 4.1 Stale context detection
- When loading a project, flag if it hasn't been updated in >7 days
- Suggest updating or archiving inactive projects

### 4.2 Decision conflict detection
- When saving a new decision, check if it contradicts an existing one
- Surface the conflict and ask user to resolve

### 4.3 Session continuity hints
- At load time, surface "last time you were working on X and left off at Y"
- Include open questions or blockers from the previous session

### 4.4 Auto-suggest save
- At the end of a long session, Claude suggests "want me to save to brain?"
- Not automatic (respecting the explicit-trigger decision), but a nudge

---

## Phase 5: Future-Proofing (v1.0.0)

Prepare for Logseq's database migration and public release.

### 5.1 Storage abstraction layer
- Separate "what to store" from "how to store it"
- Current: read/write markdown files
- Future: Logseq DB API when available
- Interface stays the same, swap the backend

### 5.2 Plugin packaging and distribution
- Clean up for public release on plugin registry
- Add installation wizard (brain-init guides new users through setup)
- Documentation and examples

### 5.3 Conflict resolution for Logseq Sync
- Detect and resolve sync conflicts gracefully
- Merge strategies for concurrent edits from different devices

### 5.4 Graph analytics
- "brain stats" — how many decisions, sessions, projects tracked
- Visualize activity over time
- Identify which projects get the most attention

---

## Priority Order

| Priority | Item | Why |
|----------|------|-----|
| 🔴 P0 | 1.1–1.4 (harden MVP) | Bugs and missing guards — fix before building more |
| 🟠 P1 | 2.1 (cross-project search) | High value, brain-load already describes it |
| 🟠 P1 | 3.1 (task skill integration) | Connects to daily workflow immediately |
| 🟡 P2 | 2.2–2.4 (smarter load/save) | Quality-of-life improvements |
| 🟡 P2 | 3.2–3.4 (multi-project) | Needed once multiple projects are tracked |
| 🟢 P3 | 4.x (intelligence layer) | Nice-to-have, adds polish |
| 🔵 P4 | 5.x (future-proofing) | When Logseq ships DB backend or plugin goes public |
