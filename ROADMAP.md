# Logseq Brain — Roadmap

## Shipped

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

## Current — v0.7.0 (backlog)

Driven by v0.6.0 first-dogfood findings (2026-05-02):

- **Durable config location.** `.brain-config.json` at the cache plugin root gets wiped on `/reload-plugins` or version bump, breaking path resolution between sessions. Replace with env-var-only contract (`LOGSEQ_BRAIN_PATH`) or a user config dir (`~/.config/logseq-brain/` on macOS/Linux, `%APPDATA%\logseq-brain\` on Windows). Touches `skills/_shared/path-resolution.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and the README install instructions.
- **Logseq normalization tolerance.** When Logseq parses journals/pages we wrote, it normalizes — drops `- ` from heading bullets, converts indents to tabs, strips empty `## Sessions` headings. Surgical Edits handle this fine via Read-before-Edit, but the algorithm prose in `skills/_shared/journey-log.md` and `skills/brain-save/SKILL.md` assumes our written format survives. Harden explicitly. Possible new `skills/_shared/logseq-format.md` adapter.
- **Re-add `HH:mm` time prefix to journey-log activity bullets.** Reverses v0.6.0's "no time prefix" design call. The original rationale was "Logseq auto-assigns `created-at::` block metadata" implying inline display, but real-world dogfood (2026-05-02) showed Logseq does NOT auto-render those timestamps visibly. Without prefixes the activity trail loses its quick-scan chronological signal. Touches `skills/_shared/journey-log.md`, activity-line examples in all four `SKILL.md`, and the v0.6.0 spec events table.

Other open candidates from the Future list will be promoted here once Logseq's roadmap clarifies which is closest to ready.

See `docs/superpowers/specs/2026-05-01-v0.6.0-design.md` for the v0.6.0 design (now shipped).

## Future — informed by Logseq's own roadmap

These items are deferred until Logseq's own work makes them clearly worthwhile.

- **Storage abstraction layer.** Decouple "what to store" from "how to store it" so the backend can swap from markdown files to Logseq's DB API without changing the skill surface. Defer until Logseq's "Markdown Mirror" feature ships and the DB version stabilizes — until then, markdown is safe.
- **Logseq DB plugin API integration.** Replace markdown file IO with Logseq's plugin API once it goes GA. Per Logseq's roadmap the API is in development; revisit when stable.
- **Headless sync via new Logseq CLI.** The new Logseq CLI supports headless sync without the desktop app, which would let LogseqBrain operate concurrently with the desktop app safely. Revisit when the CLI ships in stable.
- **Conflict resolution for Logseq Sync.** Detect and merge sync conflicts gracefully (relevant once we're touching the same files Logseq Sync is touching mid-write).
- **Graph analytics.** "brain stats" — counts of decisions, sessions, projects, activity over time.
- **Plugin packaging refinements.** Cleaner Cowork install flow, installation wizard.
