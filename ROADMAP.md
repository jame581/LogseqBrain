# Logseq Brain — Roadmap

## Shipped

### v0.8.0 — Graph hygiene
- `brain-doctor` skill — lints the whole graph for format violations that spawn phantom pages or broken macros, then repairs them after a backup + confirmation (`skills/brain-doctor/SKILL.md` + `references/checks.md`)
- **Prevention:** compose-time content-generation invariants added to `skills/_shared/logseq-format.md` (backticks not `{{ }}`; escape `#` before numbers/hex; namespaced `[[Tasks/…]]` / `[[Projects/…]]` links; markdown links not `[[file://]]`); `brain-save` and `CLAUDE.md` updated to enforce them
- **Cure (one-time):** repaired the maintainer's own graph — ~1,031 `{{ }}` broken macros, 125 phantom `#`-tags, 16 un-namespaced task links, 7 `[[file://]]` links, 7 junk/typo links across 49 pages + 49 journals
- See `docs/superpowers/specs/2026-06-23-v0.8.0-design.md`
- Shared rule catalog `skills/_shared/hygiene-rules.md` (Approach A) feeding both brain-doctor and brain-save
- 4 added detection rules (malformed-property, broken-link, duplicate-entry, structural-integrity) + a brain-save write-time self-check; see `docs/superpowers/specs/2026-06-23-v0.8.0-hygiene-deepening-design.md`

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

## Current — v0.9.0 (TBD)

Open candidates from the Future list will be promoted here once Logseq's roadmap clarifies which is closest to ready.

See `docs/superpowers/specs/2026-05-31-v0.7.0-design.md` and `docs/superpowers/specs/2026-06-23-v0.8.0-design.md` for the v0.7.0 / v0.8.0 designs (now shipped).

## Future — informed by Logseq's own roadmap

These items are deferred until Logseq's own work makes them clearly worthwhile.

- **Storage abstraction layer.** Decouple "what to store" from "how to store it" so the backend can swap from markdown files to Logseq's DB API without changing the skill surface. Defer until Logseq's "Markdown Mirror" feature ships and the DB version stabilizes — until then, markdown is safe.
- **Logseq DB plugin API integration.** Replace markdown file IO with Logseq's plugin API once it goes GA. Per Logseq's roadmap the API is in development; revisit when stable.
- **Headless sync via new Logseq CLI.** The new Logseq CLI supports headless sync without the desktop app, which would let LogseqBrain operate concurrently with the desktop app safely. Revisit when the CLI ships in stable.
- **Conflict resolution for Logseq Sync.** Detect and merge sync conflicts gracefully (relevant once we're touching the same files Logseq Sync is touching mid-write).
- **Plugin packaging refinements.** Cleaner Cowork install flow, installation wizard.
