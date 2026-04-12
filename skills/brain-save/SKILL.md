---
name: brain-save
description: >
  Save session context, decisions, and progress to the Claude Brain Logseq graph.
  Use when the user says "save to brain", "save this", "remember this",
  "update brain", "save progress", "brain save", "store this decision",
  or wants to persist the current session's work for future sessions.
---

# Brain Save

Write session context — decisions, progress, plans, implementation details — to the Claude Brain Logseq graph so it persists across sessions and devices.

## Prerequisites

The user's ClaudeBrain Logseq graph folder must be accessible.

**In Cowork:** If no folder is connected, use `request_cowork_directory` to ask the user to select their ClaudeBrain graph folder.

**In Claude Code / CLI:** The user should provide the graph path, or read it from the `LOGSEQ_BRAIN_PATH` environment variable, or from `.brain-config.json` in the plugin root (`{"graphPath": "..."}`). As a last resort, ask the user for the path.

## What to Save

Review the current conversation and identify what should be persisted. Focus on these categories:

### 1. Session Log Entry (always save this)
A brief record of what was accomplished in this session. Append to the project page's **Session Log** section.

Format:
```markdown
  - yyyy-MM-dd: Brief summary of what was done
    - Detail about specific work
    - Detail about another piece of work
```

### 2. Decisions (save when decisions were made)
Any technical, architectural, or process decisions made during the session. Append to the project page's **Decisions** section.

Format:
```markdown
  - yyyy-MM-dd: Decision title
    - context:: Why this came up
    - alternatives:: What else was considered
    - rationale:: Why this option was chosen
    - status:: accepted
```

### 3. Plan Updates (save when plans changed)
If a new plan was created or an existing one was modified, update the **Current Plan** section of the project page. Replace the existing plan content — don't append, since there should be one current plan.

### 4. Implementation Details (save when significant)
If implementation notes, setup instructions, or technical details were discussed that would be valuable in future sessions, update the **Implementation** section.

## Save Process

1. **Identify the target project.** Determine which project this session was about. If unclear, ask the user. If work spanned multiple projects, save to each relevant project page.

2. **Read the current project page** to understand existing content and avoid duplicates.

3. **Prepare the updates.** Draft what will be added/modified for each section.

4. **Write the updates** using the Edit tool to surgically update specific sections:
   - Append new session log entries to the Session Log section
   - Append new decisions to the Decisions section
   - Replace the Current Plan section if the plan changed
   - Update Implementation section if needed
   - Update the `last-updated::` property to today's date

5. **Update the journal.** Create or append to today's journal file at `journals/yyyy_MM_dd.md` (using underscores in the date). Add a brief cross-reference:

```markdown
- ## Sessions
  - [[Projects/ProjectName]]: Brief summary of session
```

6. **Update Index if needed.** If a project status changed or new cross-project information emerged, update `pages/Index.md`.

7. **Confirm to the user** what was saved, in plain language. Example: "Saved to brain: session log for today's work on the price calculator, plus the decision to use the strategy pattern."

## Important Notes

- Use the Edit tool for surgical updates — don't rewrite entire pages. This minimizes sync conflicts with Logseq Sync.
- All content must be in bullet point format (Logseq outliner).
- Properties use `key:: value` format.
- Dates always in `yyyy-MM-dd` format.
- Page links use `[[Projects/PageName]]` syntax.
- File names use triple underscore `___` for namespace separators.
- When appendi