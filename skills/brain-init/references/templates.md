# Page Templates

## Logseq Format Rules

All content written to the graph MUST follow these rules:

1. **Outliner format**: Every line of content must be a bullet point (starting with `- `). No bare paragraphs.
2. **Properties**: Use `key:: value` format. Properties go at the top of the page (page-level) or as children of a bullet (block-level).
3. **Headings**: Use `- ## Heading` (bullet + markdown heading). Never a bare `## Heading` without the bullet prefix.
4. **Indentation**: Use two spaces per indent level. Children are indented under their parent bullet.
5. **Links**: Use `[[Page Name]]` for internal links. For namespaced pages: `[[Projects/PageName]]`.
6. **Dates**: Always `yyyy-MM-dd` format (e.g., `2026-04-12`).
7. **File names**: Use triple underscore `___` for namespace separators in filenames (e.g., `Projects___MyProject.md` → appears as `Projects/MyProject` in Logseq).
8. **Journal filenames**: Use underscores in dates: `yyyy_MM_dd.md` (e.g., `2026_04_12.md`).
9. **Emphasis/bold**: Use markdown `**bold**` and `_italic_` within bullet text. Logseq renders these.
10. **Placeholders**: Use `_italic text_` for placeholder/empty sections (e.g., `_No active plan yet._`).

## Project Page Template

Use this when creating a new project page via brain-init.

```markdown
type:: project
status:: active
created:: {{today}}
last-updated:: {{today}}
focus:: {{project_description}}
next:: _No next action yet._
digest-updated:: {{today}}

- ## Digest
  - {{project_description}}
  - Now: just created; no work logged yet.
  - Map: page 0 KB
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

Replace `{{today}}` with the current date in `yyyy-MM-dd` format.
Replace `{{project_description}}` with the user-provided description or placeholder.

Note the deliberate omissions: **no `open::` line** (nothing is open on a fresh page — the property is omitted, never written as `open:: none`), and the Map carries only the page size because every section is still a placeholder stub. Both follow `skills/_shared/digest.md`. `brain-save` replaces all of this on the first real save.

## Task Page Digest

Task pages have no fixed template, but when `brain-save` or `brain-doctor` gives one a digest it is the thin form — Identity + Now + Map — plus the page-top properties `focus::`, `next::`, `digest-updated::` and the existing `status:: active | blocked | done`. See `skills/_shared/digest.md`.

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
