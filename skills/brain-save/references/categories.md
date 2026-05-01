# Save Categories

`brain-save` writes to six distinct categories. The orchestrator decides which apply to the current session based on what was discussed.

## 1. Session Log Entry (always)

A rich record of session work. Append to the project page's `## Session Log` section.

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

Include `files-modified::`, `skills-used::`, `related-tickets::`, `open-questions::` only when they have meaningful values — don't write empty properties.

## 2. Decisions (when decisions were made)

See `references/decisions.md` for the conflict-detection and cross-project rules. Format:

```markdown
  - yyyy-MM-dd: Decision title
    - context:: Why this came up
    - alternatives:: What else was considered
    - rationale:: Why this option was chosen
    - status:: accepted
```

## 3. Plan Updates (when plans changed)

If a new plan was created or an existing one modified, REPLACE the `## Current Plan` section content. There should be exactly one current plan — don't append.

## 4. Implementation Details (when significant)

If implementation notes, setup instructions, or technical details were discussed that would be valuable in future sessions, update the `## Implementation` section. Append; don't replace.

## 5. Jira Task Context (when tasks were worked on)

If the session involved Jira tasks (IDs like `PROJ-1234`), capture in `## Current Plan`:

```markdown
  - PROJ-1234: Short task title
    - status:: in-progress
    - estimate:: 3 days
    - task-folder:: Tasks\PROJ-1234\
    - summary:: Brief description of what the task involves
```

**Do NOT duplicate the full plan or estimate** — those live in the task folder. The brain stores a pointer.

Also add the task ID to the session log entry's `related-tickets::` property.

## 6. User Preferences & Meta (when discovered)

If the session revealed something new about user preferences, working style, tools, or conventions — and it's not already in `pages/Meta.md` — update Meta.

Examples to save:
- Specific code style or naming convention
- Tech stack mentions
- Behavioral preferences ("don't summarize at the end")
- Workflow conventions ("I always branch off develop")

Do NOT save:
- One-off instructions for the current session only
- Sensitive personal information
- Things obvious from the project context

Always read `pages/Meta.md` first to avoid duplicates. Add new entries under the appropriate section: User Preferences, Conventions, or Tools & Stack. Update `last-updated::` to today's date.
