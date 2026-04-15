## Summary

Describe the change and the problem it solves.

## Related issues

Link any related issues, discussions, or previous PRs.

## Type of change

- [ ] Documentation
- [ ] Skill update (brain-init / brain-load / brain-save / brain-status)
- [ ] New skill
- [ ] Plugin packaging / marketplace
- [ ] Tooling
- [ ] Other

## What changed

- [ ] Kept changes focused on the intended scope
- [ ] Updated the relevant documentation (README / ROADMAP / CLAUDE.md)
- [ ] Bumped `version` in `.claude-plugin/plugin.json` if user-facing

## Skill-specific checklist

If this PR changes a `SKILL.md`, confirm the applicable items below.

- [ ] `SKILL.md` keeps valid YAML frontmatter
- [ ] The `description` field still accurately reflects when the skill should trigger
- [ ] Generated content respects Logseq format invariants:
  - [ ] Content lives in bullet points (no bare paragraphs)
  - [ ] Properties use `key:: value` on bullet lines
  - [ ] Page links use `[[Page Name]]` / `[[Namespace/Page Name]]`
  - [ ] Filenames use `___` for namespace separators
  - [ ] Dates use `yyyy-MM-dd`; journal filenames use `yyyy_MM_dd.md`
- [ ] Writes stay surgical (Edit on specific sections, not whole-page rewrites)

## Validation

Describe how you tested the change against a real ClaudeBrain graph.

## Notes for reviewers

Any context that will help reviewers focus on the right areas.
