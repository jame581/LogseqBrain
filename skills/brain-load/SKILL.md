---
name: brain-load
description: >
  Load project context from the Claude Brain Logseq graph into the current session.
  Triggers: "load brain", "load <project>", "resume <project>", "open <project>",
  "switch to <project>", "continue work on <project>", "what do we know about <topic>".
  Don't fire for write operations (use brain-save) or generic questions about Logseq itself.
---

# Brain Load

Read project context from the Claude Brain Logseq graph and present it to Claude so work can continue seamlessly across sessions and devices.

## Prerequisites

Resolve the graph path per `skills/_shared/path-resolution.md`.

## Loading a Specific Project

When the user says "load <project>" or similar:

1. **Find the project page** using the algorithm in `references/matching.md`.

2. **Read the matched project page.** In **brief** mode (default), read only Properties, Overview, Current Plan, and the last 3 Session Log entries. In **full** mode, read everything (see "Load Modes" below).

3. **Read related context** (full mode only). Follow `[[link]]` references inside the project page if they're critical (e.g., a linked design doc). Skip in brief mode.

4. **Read today's journal** (`journals/yyyy_MM_dd.md`) if it exists — captures session notes from earlier today.

5. **Check active Jira tasks.** If the project's Current Plan section references task IDs (e.g., `PROJ-1234`), and the task folder is accessible, optionally read `plan.md`. Full mode or explicit user ask only — in brief mode, just mention task IDs and status.

6. **Apply staleness rules.** Use `skills/_shared/staleness.md` against the project's `last-updated::` and `status::`.

7. **Surface session continuity hints.** From the most recent Session Log entry: what was last worked on, any `open-questions::`, any blockers. Frame as: "Picking up where you left off — last session ([date]): [summary]. Open questions: [list]."

8. **Present a context summary** conversationally: project name + status + staleness, current plan/task, continuity hint, key recent decisions (full mode only), suggested next actions.

9. **Write a journey-log entry** per `skills/_shared/journey-log.md` with activity line: `loaded [[Projects/<MatchedName>]] (brief)` or `loaded [[Projects/<MatchedName>]] (full)`.

## Loading General Context

When the user says "load brain" without a project:

1. Read `pages/Index.md` for the list of all projects.
2. Read `pages/Meta.md` for user preferences and conventions.
3. Present a high-level overview: active projects, cross-project decisions, user preferences.
4. Write a journey-log entry: `loaded brain overview`.

## Searching Across the Brain

When the user asks "what do we know about X" or similar, follow the algorithm in `references/search.md`. After presenting findings, write a journey-log entry: `searched "X" · N hits`.

## Load Modes: Brief vs Full

**Brief mode** (default — "load <project>"):
1. Properties (type, status, last-updated)
2. Overview (first 5 bullets only)
3. Current Plan (full)
4. Session Log (last 3 entries only)
5. Skip Implementation, Decisions, linked context

**Full mode** ("load <project> full", "load everything about <project>"):
1. All properties
2. Full Overview
3. Full Current Plan
4. Full Implementation
5. All Decisions
6. Last 10 Session Log entries
7. Related context pages (follow `[[links]]`)
8. Today's journal entry

In brief mode, mention that more is available: "Loaded brief context. Say 'load full' for decisions, implementation details, and full history."

## Important Notes

- Be selective about reads. Token budget matters — see Task 6 for section-targeted-read patterns.
- After loading, confirm what's available and suggest next actions.
- All graph content is Logseq outliner format. See `CLAUDE.md` for invariants.
