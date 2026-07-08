# Decision Handling

`brain-save` records decisions with extra care: cross-project decisions get duplicated to the global log, and conflicting decisions are flagged.

## Cross-Project Decisions

A decision is cross-project if it affects multiple projects or is general in nature (e.g., "we're standardizing on X across all projects").

For cross-project decisions, write to BOTH:

1. The project page's `## Decisions` section (single project, normal format).
2. `pages/Decisions.md` with an extra `projects::` property:

```markdown
  - yyyy-MM-dd: Decision title
    - projects:: [[Projects/ProjectA]], [[Projects/ProjectB]]
    - context:: Why this came up
    - alternatives:: What else was considered
    - rationale:: Why this option was chosen
    - status:: accepted
```

If the decision touches multiple projects, write the per-project decision to EACH project page (not just one).

## Decision Conflict Detection

Before appending a new decision, read the existing Decisions section of the target page (and `pages/Decisions.md` for cross-project decisions). Check if any existing decision contradicts or is superseded by the new one.

Look for:

- Decisions about the same topic or component (e.g., two decisions about which auth library to use).
- Decisions where the new `rationale::` would invalidate the old one.
- Decisions with `status:: accepted` that the new one reverses.

If a conflict is found:

> "This new decision conflicts with an earlier one: [old decision title] from [date]. The old decision said [summary]. Want me to mark the old one as `status:: superseded` and add the new one?"

If the user confirms:

1. Update the old decision's `status::` from `accepted` to `superseded`.
2. Add a `superseded-by:: [new decision title]` property under the old decision.
3. Append the new decision normally.

If no conflict, append the new decision without asking.

## Decision detection (forward-only)

While composing the session summary (SKILL.md step 4), scan your own composed text for decision-shaped statements — signals: "decided", "chose X over Y", "went with", "will use", "instead of", "superseded", "rozhodnuto", "zvolili jsme". For each candidate, ask the user in one batch:

> "These N statements look like decisions — record them in Decisions? (1) … (2) …"

Approved ones are written as proper decision entries (categories.md §2: `context:: / alternatives:: / rationale:: / status:: accepted`) to the project page's `## Decisions` section — and, when the cross-project rule above applies, to `pages/Decisions.md` too. Declined ones stay as session-log prose. Never record a decision the user didn't approve; never retro-mine old session logs (explicitly out of scope for v0.9.0).
