# Page Templates

## Logseq Format Rules

All content written to the graph MUST follow these rules:

1. **Outliner format**: Every line of content must be a bullet point (starting with `- `). No bare paragraphs. **One exception: the page-top property block** — see rule 2.
2. **Properties**: Use `key:: value` format. Properties go at the top of the page (page-level) or as children of a bullet (block-level). **The page-top block is deliberately un-bulleted** — bare `type:: project` lines before the first `- `, exactly as the templates below show. This is Logseq's own page-properties form, and bulleting those lines would stop Logseq treating them as page properties. Rule 1's "every line" governs the outliner body that follows; it does not govern this block. Block-level properties, by contrast, *are* bulleted, because they are children of a bullet.
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
  - Map: pending
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
Replace `{{project_description}}` with the user-provided description — it appears **three times** in the template above: `focus::`, the Digest Identity bullet, and `## Overview`. If that description exceeds **120 bytes**, use a short form for `focus::` only — property values share that 120-byte cap, see `skills/_shared/digest.md` — and put the full text in both the Digest Identity bullet and `## Overview`; the Digest section's own cap (below) is 800 bytes for the whole section, not per bullet, so Identity is not subject to the 120-byte property limit. `oversized-digest` caps property values, and a page that is oversized the moment it is created defeats the point of seeding a digest.
The Map line is a placeholder that `brain digest Projects/<Name> --apply` replaces with the measured Map right after the page is written (brain-init step 4). Never write a figure by hand.

Note the deliberate omissions: **no `open::` line** (nothing is open on a fresh page — the property is omitted, never written as `open:: none`), and the computed Map on a fresh page is only the smaller-sections residual and the page total, because every section is still a stub under 1 KB. Both follow `skills/_shared/digest.md`. `brain-save` replaces all of this on the first real save.

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
