# Stale-Project Rules

`brain digest` prints a `staleness:` line and `brain status` a staleness column. Both are computed from `last-updated::`, `status::` and today's date. Use this phrasing:

| Level (days since `last-updated::`) | Phrasing |
|---|---|
| `fresh` (0–7) | (no message) |
| `aging` (8–14) | "Note: last updated [N] days ago." |
| `stale` (15–29, or 30+ when not `active`) | "⚠ This project hasn't been updated in [N] days. Context may be outdated — verify before acting on it." |
| `abandoned` (30+ and `status:: active`) | "This project is marked active but hasn't been touched in [N] days. Want to update it or mark it paused?" |
| `aging (no valid last-updated)` | "Project [name] has no valid `last-updated::` property — consider running brain-save to set one." |
| `exempt` | (no message) — a `done` task page, a legacy task page with no `status::` (brain-doctor's backfill is the fix, not a nag), or a session archive |
