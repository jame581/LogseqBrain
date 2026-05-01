# Logseq Brain — Roadmap

## Shipped

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

## Current — v0.6.0 (in design)

- **Journey log** — one-line activity trail in today's journal `## Activity` section, written by every brain skill use (init, load, save, status, search). Existing rich `## Sessions` summary preserved.
- **Token-frugality pass** — progressive disclosure (split each `SKILL.md` into compact orchestrator + per-skill `references/` + cross-skill `skills/_shared/`); section-targeted reads in brain-load brief mode; grep-anchored targeted reads in brain-save.
- **Description tuning** — tighter frontmatter on all four skills with explicit scope boundaries.
- **Doc refresh** — this file. Plus a `_shared/` convention note in `CLAUDE.md`. Plus a v0.6.0 manual-validation checklist in `CONTRIBUTING.md`.

See `docs/superpowers/specs/2026-05-01-v0.6.0-design.md` for the full design.

## Future — informed by Logseq's own roadmap

These items are deferred until Logseq's own work makes them clearly worthwhile.

- **Storage abstraction layer.** Decouple "what to store" from "how to store it" so the backend can swap from markdown files to Logseq's DB API without changing the skill surface. Defer until Logseq's "Markdown Mirror" feature ships and the DB version stabilizes — until then, markdown is safe.
- **Logseq DB plugin API integration.** Replace markdown file IO with Logseq's plugin API once it goes GA. Per Logseq's roadmap the API is in development; revisit when stable.
- **Headless sync via new Logseq CLI.** The new Logseq CLI supports headless sync without the desktop app, which would let LogseqBrain operate concurrently with the desktop app safely. Revisit when the CLI ships in stable.
- **Conflict resolution for Logseq Sync.** Detect and merge sync conflicts gracefully (relevant once we're touching the same files Logseq Sync is touching mid-write).
- **Graph analytics.** "brain stats" — counts of decisions, sessions, projects, activity over time.
- **Plugin packaging refinements.** Cleaner Cowork install flow, installation wizard.
