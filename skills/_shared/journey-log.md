# Journey Log

Every brain skill records a single-line entry under `## Activity` in today's journal whenever it runs. This is the "journey trail" — terse, time-ordered, distinct from the rich `## Sessions` summary that `brain-save` writes.

## When to call this

Each skill calls journey-log **once**, after completing its main work. Failures during the main work skip the journey-log call (don't log incomplete work).

## Input

A single `activity-line` string describing what happened. No leading bullet marker — this module adds the bullet.

Examples:

- `"loaded [[Projects/LogseqBrain]] (brief)"`
- `"saved [[Projects/LogseqBrain]]"`
- `"searched \"strategy pattern\" · 3 hits"`
- `"viewed dashboard"`
- `"initialized graph at /path/to/ClaudeBrain"`
- `"created project [[Projects/MyProject]]"`

## Algorithm

1. **Read config.** Read `.brain-config.json` in the plugin root if present. If it contains `"journeyLog": false`, return immediately — no write.
2. **Compute today's journal path:** `<graphPath>/journals/yyyy_MM_dd.md` (date with underscores, e.g., `2026_05_01.md`).
3. **If the journal file does not exist:** create it with this content (Write tool):

   ```markdown
   - ## Sessions
   - ## Activity
     - {{activity-line}}
   ```

   Then stop.

4. **If the journal file exists but lacks `## Activity`:** insert `- ## Activity` after the last bullet of `## Sessions` (or at end of file if `## Sessions` is also missing). Then append the new bullet under it.

5. **If the journal file exists with `## Activity`:** append a child bullet at the end of the `## Activity` section, before the next `##` heading or end of file.

   Surgical Edit pattern: locate the last bullet under `## Activity`, replace it with `<old_last_bullet>\n  - <activity-line>`. Or if the section is empty, replace `- ## Activity\n` with `- ## Activity\n  - <activity-line>\n`.

## Format rules

- Bullet indented two spaces under `- ## Activity`.
- No leading time prefix — Logseq auto-assigns `created-at::` block metadata when the file is parsed.
- One bullet per call. Multiple calls in the same session each produce a new bullet.

## Side effects

A single Edit (or Write, for first-time creation) on `<graphPath>/journals/yyyy_MM_dd.md`. No reads of the project page, no reads of `pages/Index.md`. Cheap.

## Failure modes

- **`.brain-config.json` invalid JSON:** treat as if `journeyLog` is `true` (default) and log the error to the user, but don't block the main skill.
- **Graph path not resolved:** journey-log is called from skills that have already resolved the path. If the path is missing here, that's a programming error in the calling skill — surface it.
- **Journal write fails (e.g., permission denied):** report the error to the user but don't fail the parent skill. The brain-load itself succeeded; the journey-log entry just didn't land.
