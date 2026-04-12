# Page Templates

## Project Page Template

Use this when creating a new project page via brain-init.

```markdown
type:: project
status:: active
created:: {{today}}
last-updated:: {{today}}

- ## Overview
  - {{project_description}}
- ## Current Plan
  - _No active plan yet._
- ## Implementation
  - _Implementation details and notes go here._
- ## Decisions
  - _Project-specific decisions._
- ## Session Log
  - _Session entries are added by brain-save._
```

Replace `{{today}}` with current date in `yyyy-MM-dd` format.
Replace `{{project_description}}` with user-provided description or placeholder.

## Session Log Entry Template

Used by brain-save when appending to a project's Session Log section.

```markdown
  - {{date}}: {{summary}}
    - {{detail_1}}
    - {{detail_2}}
```

## Decision Entry Template

Used by brain-save when recording a decision.

```markdown
  - {{date}}: {{decision_title}}
    - context:: {{why_this_came_up}}
    - alternatives:: {{what_else_was_considered}}
    - rationale:: {{why_this_was_chosen}}
    - status:: accepted
```

## Plan Entry Template

Used by brain-save when recording or updating a task plan.

```markdown
  - {{task_id}}: {{task_title}}
    - status:: {{status}}
    - estimate:: {{estimate}}
    - **Plan:**
      - {{step_1}}
      - {{step_2}}
      - {{step_3}}
    - **Notes:**
      - {{any_additional_context}}
```

## Journal Entry Template

Used for daily journal pages in `journals/yyyy_MM_dd.md`.

```markdown
- ## Sessions
  - [[Projects/{{project_name}}]]: {{brief_summary}}
    - {{detail}}
```
