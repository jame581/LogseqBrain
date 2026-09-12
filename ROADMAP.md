# Logseq Brain — Roadmap

## Shipped

### v0.10.0 — Digest layer: cheap recall, honest coverage
- `## Digest` section + `focus::` / `next::` / `open::` / `digest-updated::` properties on project and task pages (`skills/_shared/digest.md`)
- brain-load brief mode = one Read of the digest (~2 KB regardless of page size), with automatic fallback to the pre-digest path on un-backfilled pages
- Lazy retrieval ladder (`skills/_shared/escalation.md`) — announced escalation from grep to bounded read to consent-gated whole-page read
- Truncation honesty: byte-denominated budgets, measure-before-read, and a mandatory coverage statement on every partial read (`skills/_shared/section-locator.md` rewritten)
- brain-save refreshes the digest unconditionally on every save; rebuild-from-source is the corrective path
- brain-status dashboard from a single ripgrep over digest properties
- 4 new hygiene rules (`missing-digest`, `stale-digest`, `stale-map`, `oversized-digest`) + brain-doctor guided digest backfill
- Explicit **Logseq OG only** targeting
- See `docs/superpowers/specs/2026-07-25-v0.10.0-design.md`

### v0.9.0 — Prevention, lifecycle, findability
- `jira-markup` hygiene rule — Jira drafts stored verbatim in fenced code blocks; unfenced residue reported by brain-doctor
- Mechanical post-write verify in brain-save (grep the files just written; fix + re-verify)
- Task lifecycle: `status:: active|blocked|done` on task pages, brain-status grouping, brain-load brief skips done, one-time guided backfill via brain-doctor
- Session-log rotation to `Projects/<Name>/SessionArchive` (suggestion-based, 64 KB / 40 entries / 90 days)
- Findability: unconditional `Index.md` one-liner refresh on save; forward-only decision prompting
- Rule quality: `duplicate-entry` false positives fixed; punctuation-aware `bare-hash-tag`
- See `docs/superpowers/specs/2026-07-07-v0.9.0-design.md`

### v0.8.0 — Graph hygiene
- `brain-doctor` skill — lints the whole graph for format violations that spawn phantom pages or broken macros, then repairs them after a backup + confirmation (`skills/brain-doctor/SKILL.md` + `skills/_shared/hygiene-rules.md`)
- **Prevention:** compose-time content-generation invariants added to `skills/_shared/logseq-format.md` (backticks not `{{ }}`; escape `#` before numbers/hex; namespaced `[[Tasks/…]]` / `[[Projects/…]]` links; markdown links not `[[file://]]`); `brain-save` and `CLAUDE.md` updated to enforce them
- **Cure (one-time):** repaired the maintainer's own graph — ~1,031 `{{ }}` broken macros, 125 phantom `#`-tags, 16 un-namespaced task links, 7 `[[file://]]` links, 7 junk/typo links across 49 pages + 49 journals
- Shared rule catalog `skills/_shared/hygiene-rules.md` (Approach A) feeding both brain-doctor and brain-save
- 4 added detection rules (malformed-property, broken-link, duplicate-entry, structural-integrity) + a brain-save write-time self-check
- See `docs/superpowers/specs/2026-06-23-v0.8.0-design.md` and `docs/superpowers/specs/2026-06-23-v0.8.0-hygiene-deepening-design.md`

### v0.7.0 — Durability, format tolerance, first analytics
- Durable config: `LOGSEQ_BRAIN_PATH` → user config dir (`%APPDATA%\logseq-brain\config.json` / `~/.config/logseq-brain/config.json`) → ask-and-persist; survives `/reload-plugins`; one-time legacy `.brain-config.json` migration
- `skills/_shared/logseq-format.md` — normalization-tolerance reference (read-before-edit, anchor on heading text); `section-locator.md` Grep pattern hardened to tolerate Logseq's normalized (no `- `) headings
- `HH:mm` time prefix restored on journey-log activity bullets (reverses v0.6.0 call)
- `brain-stats` analytics mode on `brain-status` (project/decision/session counts + 30-day activity window)

### v0.6.0 — Journey log + token frugality
- Journey log (`## Activity` section in today's journal, one bullet per brain skill use)
- Progressive disclosure: each `SKILL.md` split into orchestrator + per-skill `references/` + cross-skill `skills/_shared/` (path-resolution, journey-log, staleness, section-locator)
- Section-targeted reads in brain-load (brief mode) and brain-save (grep-anchored) — meaningful token reduction on large project pages
- Description tuning on all four skills (purpose-first frontmatter with explicit "Don't fire for X" scope boundaries)
- ROADMAP rewrite (Shipped/Current/Future), CLAUDE.md `_shared/` convention, CONTRIBUTING.md v0.6.0 manual validation checklist
- New `.brain-config.json` `journeyLog` toggle (default `true`)

### v0.5.0 — Intelligence layer
- Stale-context detection on load
- Decision conflict detection on save (mark old as `superseded`)
- Session continuity hints (last-worked-on, open questions)
- Auto-suggest save (suggestion only — never persists without confirmation)

### v0.4.0 — Multi-project & integration
- Cross-project decision log (`pages/Decisions.md`)
- Multi-project session support
- Project status dashboard (`brain-status` skill)
- Jira task pointer pattern (task ID + folder + summary, no plan duplication)

### v0.3.0 — Richer context
- Cross-project search ("what do we know about X")
- Smart context budgeting (brief vs. full load modes)
- Richer session log (files-modified, skills-used, related-tickets, open-questions properties)
- Meta page auto-population from session-discovered preferences

### v0.2.0 — Hardened MVP
- Fuzzy project name matching
- Project-page existence guard in brain-save
- `journals/` directory creation in brain-init
- Logseq format compliance (bullets, properties, namespaced filenames)

### v0.1.0 — MVP
- Three skills: `brain-init`, `brain-load`, `brain-save`
- Save/load cycle against a Logseq graph
- Initial graph layout (`pages/`, `journals/`, `Index.md`, `Meta.md`)

## Current — v0.11.0: Deterministic helper

- One POSIX `sh` + `awk` helper (`skills/_shared/bin/brain`) performs every mechanical step: section measurement, the digest Map (`digest --apply`), cap checks, scoped count-first search, Logseq-faithful lint (validated against Logseq's parse cache), and the activity line.
- Target: saves drop from ~29 tool calls to ~10–13, loads from ~12 to ~3. Measured by `tools/measure/` two weeks after release.
- First test suite (`tests/`, CI on three awks) and dev tools (`tools/oracle`, `tools/measure`).
- See `docs/superpowers/specs/2026-09-11-v0.11.0-design.md`.

## Future — OG (markdown)

- **Instruction diet, part 2** — trim the remaining prose now that the helper owns the mechanics.
- **Graph policy** — task-first entry (stub task pages, loading by Jira ID), size-based Session Log rotation, a property vocabulary and the `:property-pages/enabled?` setting, re-checking stale `open::` items on save.
- **Maintainer graph cleanup** — fix what `brain lint --all` reports, re-index in Logseq, backfill digests.
- **Block refs for decisions.** Write a cross-project decision once with `id:: <uuid>` and reference it as `((uuid))` from `pages/Decisions.md`, ending the physical duplication between the project page and the decision log.
- **`{{query}}` dashboards.** Live Logseq-rendered views (active projects, open blockers) that cost nothing to maintain. Human-facing only — no token effect for Claude.
- **Retrieval rethink.** Drop project pre-loading entirely; grep purely on demand with `Index.md` as the only always-loaded surface. v0.10.0's escalation ladder is a bounded step in this direction.
- **Conflict resolution for Logseq Sync.** Detect and merge sync conflicts gracefully.
- **Plugin packaging refinements.** Cleaner Cowork install flow, installation wizard.

## DB version (future track) — not applicable to OG

Logseq split in 2026: **OG** (markdown) moved to <https://github.com/logseq/og> and entered **maintenance mode** — security and Electron upgrades only, no new features. The **DB** (SQLite) version continues at the original repo; its beta was announced 2026-07-13.

This plugin targets OG. The items below were previously listed as "deferred until Logseq's roadmap clarifies"; it has now clarified in the negative for OG, so they are parked here rather than deleted — they become live again only if this plugin ever targets DB graphs.

- **Storage abstraction layer.** Moot for OG: markdown is permanently safe, since OG will not gain a DB backend.
- **Logseq DB plugin API integration.** Not an OG capability. The plugin API only runs inside the desktop app.
- **Headless sync via the Logseq CLI.** `@logseq/cli` serves **DB graphs only** and cannot operate on a markdown graph.

Rejected outright (recorded so it is not re-proposed): driving a file graph through `logseq/nbb-logseq` or `cldwalker/logseq-query` to run Datalog from the command line. It works, but `logseq-query` is alpha and it would put a Node/nbb runtime under a plugin whose whole identity is markdown skills with no runtime code. [v0.11.0 note: the plugin now carries one narrow POSIX sh/awk helper; what was rejected here is a heavier Node/nbb runtime, and that still stands.]
