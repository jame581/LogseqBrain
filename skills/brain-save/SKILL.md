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
A rich record of what was accomplished in this session. Append to the project page's **Session Log** section.

Format:
```markdown
  - yyyy-MM-dd: Brief summary of what was done
    - Detail about specific work
    - Detail about another piece of work
    - files-modified:: comma-separated list of key files changed (if applicable)
    - skills-used:: comma-separated list of skills/tools used (if applicable)
    - related-tickets:: comma-separated Jira ticket IDs (if applicable)
    - open-questions:: any unresolved questions or blockers to carry forward
```

Include `files-modified`, `skills-used`, `related-tickets`, and `open-questions` properties only when they have meaningful values — don't add empty ones. These properties help future sessions understand not just what happened, but what was touched and what's still pending.

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

### 5. User Preferences & Meta (save when discovered)
If during the session you learn something new about the user's preferences, working style, tools, or conventions — and it's not already in `pages/Meta.md` — update the Meta page. Examples:
- User prefers a specific code style or naming convention
- User mentions their tech stack or commonly used tools
- User expresses a preference for how Claude should behave (e.g., "don't summarize at the end", "keep responses short")
- User shares conventions about their workflow (e.g., "I always branch off develop")

Read `pages/Meta.md` first to check what's already there. Add new entries under the appropriate section (User Preferences, Conventions, or Tools & Stack). Update `last-updated::` to today's date.

Do NOT save to Meta:
- One-off instructions that only apply to the current session
- Sensitive personal information (addresses, IDs, health info)
- Things that are obvious from the project context

## Save Process

1. **Identify the target project.** Determine which project this session was about. If unclear, ask the user. If work spanned multiple projects, save to each relevant project page.

2. **Verify the project page exists.** Check that `pages/Projects___<ProjectName>.md` is present in the graph folder. If it does not exist:
   - Tell the user: "No project page found for [name]. Would you like me to create one first?"
   - If the user agrees, follow the brain-init "Adding a New Project" flow to create the page, then continue with the save.
   - If the user declines, ask which existing project to save to (list available projects from the `pages/` directory).
   - Never write session data to a non-existent project page.

3. **Read the current project page** to understand existing content and avoid duplicates.

4. **Prepare the updates.** Draft what will be added/modified for each section.

5. **Write the updates** using the Edit tool to surgically update specific sections:
   - Append new session log entries to the Session Log section
   - Append new decisions to the Decisions section
   - Replace the Current Plan section if the plan changed
   - Update Implementation section if needed
   - Update the `last-updated::` property to today's date

6. **Update the journal.** Create or append to today's journal file at `journals/yyyy_MM_dd.md` (using underscores in the date). Add a brief cross-reference:

```markdown
- ## Sessions
  - [[Projects/ProjectName]]: Brief summary of session
```

7. **Update Meta if needed.** If new user preferences, conventions, or tool info was discovered during the session, update `pages/Meta.md` (see category 5 above).

8. **Update Index if needed.** If a project status changed or new cross-project information emerged, update `pages/Index.md`.

9. **Confirm to the user** what was saved, in plain language. List each thing that was written. Example: "Saved to brain: session log for today's work on the price calculator, the decision to use the strategy pattern, and added 'prefers strategy pattern over switch statements' to your Meta preferences."

## Important Notes

- Use the Edit tool for surgical updates — don't rewrite entire pages. This minimizes sync conflicts with Logseq Sync.
- All content must be in bullet point format (Logseq outliner).
- Properties use `key:: value` format.
- Dates always in `yyyy-MM-dd` format.
- Page links use `[[Projects/PageName]]` syntax.
- File names use triple underscore `___` for namespace separators.
- When appending to a section, place new entries at the end of the existing content in that section (before the next `##` heading).
- Never overwrite the entire project page — only update the specific sections that changed.
- If the `journals/` directory doesn't exist, create it before writing the journal entry.