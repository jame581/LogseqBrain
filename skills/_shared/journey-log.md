# Journey Log

Every brain skill records one line under `## Activity` in today's journal, once, after its main work succeeds. Skip it when the work failed:

    brain activity "<activity line>"

The helper adds the `HH:mm` prefix. It creates the journal, or the `- ## Activity` heading after the whole `## Sessions` block, when either is missing. It matches Logseq's reformatted headings and indentation, and does nothing when the user config sets `"journeyLog": false`.

Activity lines:
- `loaded [[Projects/X]] (digest)` · `(brief)` · `(full)` — or `[[Tasks/ID]]`
- `saved [[Projects/X]]`
- `searched "strategy pattern" · 3 hits`
- `viewed dashboard` · `viewed brain stats`
- `ran brain-doctor · fixed N issues` · `ran brain-doctor (clean)` · `backfilled N digests`
- `initialized graph at <path>` · `created project [[Projects/X]]`

If the call fails, tell the user the activity line didn't land. Never fail the parent skill over it.
