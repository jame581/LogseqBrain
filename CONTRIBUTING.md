# Contributing to logseq-brain

Thanks for your interest in contributing! `logseq-brain` is a Claude Code plugin that gives agents persistent memory via a user-owned [Logseq](https://logseq.com) graph. It has **no build step and no runtime code** — the plugin is entirely markdown skills (`skills/<name>/SKILL.md`) plus `.claude-plugin/plugin.json`. The agent itself is the runtime.

Please open an issue before large changes so we can align on scope.

## Project layout

```
.claude-plugin/
  plugin.json           # Plugin metadata (name, version, author)
skills/
  brain-init/SKILL.md   # First-time graph setup + new project pages
  brain-load/SKILL.md   # Load project context into a session
  brain-save/SKILL.md   # Surgical append of logs, decisions, plan updates
  brain-status/SKILL.md # Dashboard across all projects
ROADMAP.md              # Source of truth for shipped vs planned work
CLAUDE.md               # Guidance for agents working in this repo
```

## Ways to contribute

- **Bug reports** — use the issue template, include affected skill, AI platform, and Logseq version.
- **Skill improvements** — tighten `description` triggers, clarify steps, fix fuzzy matching / Logseq format edge cases.
- **Documentation** — README, ROADMAP, cross-platform install notes (Copilot CLI, Gemini CLI).
- **New skills** — only if they fit the save/load cycle and don't duplicate existing behavior. Discuss in an issue first.

## Editing a skill

Skills are YAML-frontmatter markdown files. The `description` field is load-bearing — it's what the agent reads to decide when to invoke the skill, so changes to it should be deliberate.

```yaml
---
name: brain-save
description: Use when the user asks to save, persist, remember, or log session progress to the brain ...
---
```

Keep the body structured around the operations the skill performs. Prefer concrete examples over abstract explanation — skills are instructions, not documentation.

## Logseq format invariants (non-negotiable)

Skills generate content that must round-trip through Logseq's outliner without corruption. Any change to a skill must respect these:

- **Filenames use triple underscore `___` for namespace separators.** `pages/Projects___MyProject.md` renders as `Projects/MyProject` in Logseq.
- **All content must be bullet points.** No bare paragraphs — Logseq is an outliner and swallows them.
- **Properties use `key:: value` on bullet lines** (e.g. `status:: accepted`).
- **Page links use `[[Page Name]]` or `[[Namespace/Page Name]]`.**
- **Dates are always `yyyy-MM-dd`.** Journal filenames use underscores: `journals/yyyy_MM_dd.md`.
- **Writes must be surgical** — use `Edit` to update specific sections, never rewrite whole pages. This is what keeps Logseq Sync from producing cross-device conflicts.

See [`CLAUDE.md`](./CLAUDE.md) for the full set of architectural constraints.

## Validating changes

There is no test suite. Validation means running the skill against a real ClaudeBrain graph:

1. Point `LOGSEQ_BRAIN_PATH` (or `.brain-config.json`) at a throwaway Logseq graph.
2. Trigger the skill via the agent (e.g. "load logseq-brain", "save to brain").
3. Inspect the resulting pages in Logseq desktop — make sure bullets render, properties parse, links resolve.
4. For `brain-save`, check that the Edit was surgical (no whole-page rewrite).

## Releasing a new version

Releases follow semver and are cut from `main`.

1. Update `.claude-plugin/plugin.json` → `"version": "X.Y.Z"`.
2. Update `ROADMAP.md` if phase status changed.
3. Commit with a `chore: prepare vX.Y.Z release` message.
4. Tag and push:
   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z — <title>"
   git push origin vX.Y.Z
   ```
5. Create a GitHub release with notes summarizing changes.
6. Bump the version in [`skillsmith`](https://github.com/jame581/skillsmith) `.claude-plugin/marketplace.json` so new installs pick up the release.

## Pull request checklist

- [ ] Focused scope — one concern per PR
- [ ] `SKILL.md` frontmatter still valid; `description` still accurately reflects when the skill should trigger
- [ ] Logseq format invariants respected in any generated-content examples
- [ ] README / ROADMAP / CLAUDE.md updated if user- or contributor-facing
- [ ] `version` bumped in `.claude-plugin/plugin.json` if user-facing
- [ ] Tested against a real ClaudeBrain graph

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](./LICENSE).
