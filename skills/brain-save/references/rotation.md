# Session Log Rotation

Keeps hot project pages lean. Suggestion-only — brain-save proposes, the user confirms, nothing moves without confirmation.

## Trigger

After appending a session entry to a project page, check (one Bash call: `wc -c` on the file + `grep -c` of session-entry bullets under `## Session Log`):

- file size > **64 KB**, or
- more than **40** session entries.

Either → suggest: "This page is <size>/<N> entries. Move session entries older than 90 days to `[[Projects/<Name>/SessionArchive]]`?" Judgment near the line is fine (don't nag at 63.9 KB every save). Before suggesting, check whether any Session Log entries are actually older than 90 days (the same date scan used in the rotation procedure's "Identify the cut" step) — if none qualify, don't suggest rotation and don't create anything; the page is large but all entries are recent, so there is nothing to move yet. Re-check on later saves once entries age past the cutoff.

## Rotation procedure (on confirmation)

1. **Identify the cut.** Session Log entries dated more than **90 days** before today move; newer entries stay. Never split a dated entry — an entry moves whole (its date bullet plus all children).
2. **Create the archive page only if it does not already exist** (first rotation): `pages/Projects___<Name>___SessionArchive.md` with:
   ```markdown
   type:: session-archive
   project:: [[Projects/<Name>]]
   created:: yyyy-MM-dd
   - ## Archived Session Log
     - _Entries rotated from [[Projects/<Name>]] by brain-save._
   ```
   If the page exists, leave it untouched and go to step 3 (append under its `## Archived Session Log`).
3. **Move in one confirmed batch:** append the moving entries (verbatim, oldest-first) under `## Archived Session Log`, then delete them from the project page — surgical Edits on both sides, respecting `skills/_shared/logseq-format.md` survival rules (read-before-edit, anchor on heading text).
4. **Marker bullet:** ensure the project page's `## Session Log` has as its first child: `- Older entries: [[Projects/<Name>/SessionArchive]]` (add once; don't duplicate on later rotations).
5. **Verify:** entry count before == entries kept + entries archived; run the "Post-write verify (scoped)" procedure from `skills/_shared/hygiene-rules.md` over both files.

## Exclusions (enforced elsewhere)

Archive pages are excluded from brain-load brief mode, brain-status project listing, and staleness checks (`type:: session-archive`). Cross-graph search still reaches them — that's the point of keeping the original wording instead of lossy summaries.
