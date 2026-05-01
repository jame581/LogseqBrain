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
ROADMAP.md              # Shipped / Current / Future phases (verify shipped status by reading skills)
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

There is no test suite. Validation is a manual round-trip against a scratch Logseq graph. Run this checklist before tagging a release.

### Setup

```bash
mkdir -p /tmp/scratch-brain
export LOGSEQ_BRAIN_PATH=/tmp/scratch-brain
```

(On Windows: `$env:LOGSEQ_BRAIN_PATH = "C:\temp\scratch-brain"`.)

### Checklist

1. `init brain` — verify `pages/Index.md`, `Meta.md`, `Decisions.md`, `logseq/config.edn`, `journals/.gitkeep` are created. Verify today's journal is created with `## Sessions` (empty) and `## Activity` containing one bullet (`initialized graph at <path>`).
2. `init brain project ScratchProject` — verify `pages/Projects___ScratchProject.md` is created. Verify a second `## Activity` bullet (`created project [[Projects/ScratchProject]]`).
3. `save to brain — we decided to use X, made progress on Y, the user prefers Z` — verify session log + decision + Meta updates. Verify today's `## Sessions` gains a project link. Verify `## Activity` gains `saved [[Projects/ScratchProject]]`.
4. `load ScratchProject` — verify brief-mode load. Verify `## Activity` gains `loaded [[Projects/ScratchProject]] (brief)`.
5. `load ScratchProject full` — verify full-mode load. Verify `## Activity` gains `loaded [[Projects/ScratchProject]] (full)`.
6. `brain status` — verify dashboard. Verify `## Activity` gains `viewed dashboard`.
7. `what do we know about X` — verify search. Verify `## Activity` gains `searched "X" · N hits`.
8. **Token check.** Add ~200 lines of fake Session Log entries to the project page. Re-run `load ScratchProject` (brief) and observe Read tool calls. Each Read should have a small `limit` (~30 lines). No full-file Reads.
9. **Surgical edits.** For `brain-save`, confirm the Edit was anchored to a section (no whole-page rewrite).
10. **Config toggle.** Set `.brain-config.json` `{"journeyLog": false}`. Re-run any of the above. Verify `## Activity` does NOT gain a new bullet. Restore to `journeyLog: true` and verify activity logging resumes.

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
