# Save Categories — long form

`brain-save`'s SKILL.md step 4 carries the routine formats: the Session Log entry, Current Plan (replace, one plan), the Jira pointer, Implementation (append when significant) and decision detection. This file keeps the long forms that a routine save doesn't need.

## Decisions (when approved)

Conflict detection and the cross-project copy are in `references/decisions.md`. Format:

```markdown
  - yyyy-MM-dd: Decision title
    - context:: Why this came up
    - alternatives:: What else was considered
    - rationale:: Why this option was chosen
    - status:: accepted
```

## Jira task pages

If the task has its own page (`pages/Tasks___<ID>.md`), keep its page-top `status::` current: `active` while worked on, `blocked` when explicitly blocked, `done` on confirmed completion (suggest, never assume). The `## Current Plan` pointer's `status::` and the task page's page-top `status::` should agree. A pointer looks like:

```markdown
  - PROJ-1234: Short task title
    - status:: active
    - estimate:: 3 days
    - task-folder:: Tasks\PROJ-1234\
    - summary:: Brief description of what the task involves
```

**Do NOT duplicate the full plan or estimate**: those live in the task folder.

## 6. User preferences & Meta (when discovered)

If the session revealed something new about user preferences, working style, tools or conventions, and it is not already in `pages/Meta.md`, update Meta (pass it to `save-begin --also`).

Examples to save:
- a specific code style or naming convention;
- tech stack mentions;
- behavioural preferences ("don't summarize at the end");
- workflow conventions ("I always branch off develop").

Do NOT save:
- one-off instructions for the current session only;
- sensitive personal information;
- things obvious from the project context.

Read `pages/Meta.md` first (`brain read pages/Meta.md '<section>'`) to avoid duplicates. Add new entries under the appropriate section: User Preferences, Conventions, or Tools & Stack. Update `last-updated::` to today.
