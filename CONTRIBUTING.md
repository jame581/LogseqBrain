# Contributing to logseq-brain

Thanks for your interest in contributing! `logseq-brain` is a Claude Code plugin that gives agents persistent memory via a user-owned [Logseq](https://logseq.com) graph. It has **no build step**. The plugin is markdown skills (`skills/<name>/SKILL.md`), `.claude-plugin/plugin.json`, and — since v0.11.0 — one POSIX `sh` + `awk` helper (`skills/_shared/bin/brain` plus `skills/_shared/lib/*.awk`) that performs the mechanical steps: section measurement, the digest Map, caps, scoped search, lint, the activity line. The agent supplies the judgment.

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
  brain-doctor/SKILL.md # Graph-hygiene lint + repair (phantom pages, broken macros)
  _shared/bin/brain     # The helper: a POSIX sh dispatcher
  _shared/lib/*.awk     # The helper's awk programs
tests/                  # Golden-file suite for the helper: `sh tests/run.sh`
tools/                  # Dev-only oracle and measurement scripts, not shipped
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

Two layers. **Automated:** `sh tests/run.sh`, the golden-file tests for the helper; CI runs them on mawk, BWK awk and gawk on every push. **Manual:** the round-trip below against a scratch graph, before tagging a release.

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
4. `load ScratchProject` — verify a digest-mode load (a page created by `brain-init` ships with a digest). Verify `## Activity` gains `loaded [[Projects/ScratchProject]] (digest)`. `(brief)` appears only for a page with no digest — see step 20.
5. `load ScratchProject full` — verify full-mode load. Verify `## Activity` gains `loaded [[Projects/ScratchProject]] (full)`.
6. `brain status` — verify dashboard. Verify `## Activity` gains `viewed dashboard`.
7. `what do we know about X` — verify search. Verify `## Activity` gains `searched "X" · N hits`.
8. **Token check.** Add ~200 lines of fake Session Log entries, then load and save. Count tool calls per operation (`python tools/measure/cost.py --since <today>`): a digest load ≤ 4, a save ≤ 13. No full-file Reads.
9. **Surgical edits.** For `brain-save`, confirm the Edit was anchored to a section (no whole-page rewrite).
10. **Config toggle.** Set `"journeyLog": false` in the user config file (`%APPDATA%\logseq-brain\config.json` on Windows; on macOS/Linux `$XDG_CONFIG_HOME/logseq-brain/config.json` if `XDG_CONFIG_HOME` is set, else `~/.config/logseq-brain/config.json`). Re-run any of the above. Verify `## Activity` does NOT gain a new bullet. Restore to `journeyLog: true` and verify activity logging resumes.
11. **Durable config.** Resolve a path by answering the prompt; confirm it persists to the user config file. Simulate `/reload-plugins` (or delete the plugin cache) and re-run — confirm no re-prompt. Set `LOGSEQ_BRAIN_PATH` to a different graph and confirm it overrides the file.
12. **Brain stats.** Run "brain stats" against a graph with ≥2 projects; confirm counts match the files and "brain status" still shows the plain dashboard.
13. **Jira draft fencing.** Save a session containing a Jira comment draft — verify the draft lands fenced (pointer bullet + fenced code block), and `brain check` reports it clean.
14. **brain check catches a deliberate violation.** Compose a bare `#12` and a `C#-parity` into a save; verify `brain check` reports both as new and the save fixes them.
15. **brain-doctor residue + duplicate-entry accuracy.** Run brain-doctor — verify it reports unfenced Jira residue outside fences, and reports zero `duplicate-entry` false positives on repeating property lines (e.g. `skills-used::`) and same-day journal entries with distinct `HH:mm` prefixes.
16. **Guided task-status backfill.** Run the guided backfill via brain-doctor against task pages missing `status::` — verify statuses are seeded on confirmation, "brain status" groups tasks correctly afterward, and a brief-mode `load <project>` skips the `done` task pages.
17. **Session Log rotation.** Grow a project page past 64 KB or 40 Session Log entries — verify brain-save suggests rotation, and on confirmation entries older than 90 days move to `Projects___<Name>___SessionArchive.md` with `type:: session-archive` and a marker link on the main page.
18. **Index refresh + decision prompt.** Run a normal save — verify the project's `Index.md` one-liner is refreshed unconditionally, and the decision prompt fires only when the session content is decision-shaped (not on unrelated saves).
19. **Digest round-trip:** save to a project → `digest-updated::` is today, and `brain digest <page>` reports `map: ok` and the section under 800 B.
20. **Backward compatibility:** load a project page that has no `## Digest` → `brain digest` prints the section table, the fallback reads Overview, Current Plan and the Session Log tail with coverage lines, and a digest is *offered*, not built.
21. **Coverage honesty:** every load and every partial section read states what it did not read.
22. **Escalation:** a question answerable only from the Session Log triggers an announced `brain search --page` (counts first), then a bounded `--context` or `brain tail` read — never a whole-page read.
23. **Dashboard:** `brain status` is one call; a project with no digest falls back alone, and the count is reported.
24. **Doctor:** `missing-digest` lists exactly the un-backfilled pages largest-first; `backfill digests` states the read cost before doing any work.
25. **Oracle.** `python tools/oracle/oracle.py --graph <graph>` exits 0 on the live graph and on `tools/oracle/fixture-graph`. For the fixture graph, copy it **outside the repo first** and open the copy in Logseq desktop (see `tools/oracle/README.md`) — opening the in-tree copy makes Logseq generate `logseq/bak`, `logseq/version-files`, and possibly `.recycle/` inside the tracked working tree, none of which `.gitignore` covers, so a careless `git add` commits generated cruft.
26. **PowerShell host.** On Windows, run `brain status` through Git's `bash.exe` from PowerShell (`skills/_shared/run-brain.md`) and confirm the output matches the Bash run.

## Releasing a new version

Releases follow semver and are cut from `main`.

0. The `tests` workflow is green on the release commit.
1. Update `.claude-plugin/plugin.json` → `"version": "X.Y.Z"`.
2. Update `ROADMAP.md` if phase status changed.
3. Commit with a `chore: prepare vX.Y.Z release` message.
4. Tag and push:
   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z — <title>"
   git push origin vX.Y.Z
   ```
5. Create a GitHub release with notes summarizing changes.
6. Rebuild the `.plugin` archive from committed content and verify it before shipping — nothing else keeps it current, and a stale one silently ships old skills to Cowork:
   ```bash
   git archive --format=zip -o logseq-brain.plugin HEAD .claude-plugin skills README.md
   python -m zipfile -l logseq-brain.plugin
   ```
   Confirm the listing contains `skills/_shared/bin/brain` and `skills/_shared/lib/core.awk`, and contains **no** `tests/` or `tools/` entries.
7. Bump the version in [`skillsmith`](https://github.com/jame581/skillsmith) `.claude-plugin/marketplace.json` so new installs pick up the release.

## Pull request checklist

- [ ] Focused scope — one concern per PR
- [ ] `SKILL.md` frontmatter still valid; `description` still accurately reflects when the skill should trigger
- [ ] Logseq format invariants respected in any generated-content examples
- [ ] README / ROADMAP / CLAUDE.md updated if user- or contributor-facing
- [ ] `version` bumped in `.claude-plugin/plugin.json` if user-facing
- [ ] Tested against a real ClaudeBrain graph

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](./LICENSE).
