# Section-Targeted Reads

Project pages and journals can grow to thousands of lines. Reading them whole wastes tokens. This pattern — used by `brain-load`, `brain-save`, and `brain-status` — locates a section by its heading and reads only that section.

## When to use

- `brain-load` brief/full mode: read each project-page section needed.
- `brain-save`: read each section before appending, to detect duplicates and anchor surgical Edits.
- `brain-status`: read just the property block + first bullet of `## Current Plan` + last entry of `## Session Log` per project.

## Algorithm

1. **Read the property block** (always at the top, before any heading): Read with offset 0, limit 10. This captures `type::`, `status::`, `last-updated::`, `created::` and other page-level properties.

2. **Locate sections** with Grep:
   - `output_mode: "content"`
   - `-n: true`
   - pattern: `^- ## (SectionName1|SectionName2|...)` — list every section you might need in a single Grep call
   - file: the project page or journal path

   This returns one line per matching heading with its line number.

3. **Read each section** with `Read`:
   - offset = the heading's line number (from the Grep result)
   - limit = `next-section-line - this-section-line`, OR ~50 lines if it's the last section in the file (no next heading), OR ~30 lines if you only need a quick scan in brief mode

4. **Use the section content** for either:
   - **Reading** (brain-load, brain-status): present what was needed.
   - **Writing** (brain-save): include enough surrounding lines in the Edit `old_string` to make it unique within the file.

## Token-frugality target

A project page with 1000+ lines becomes 30-150 lines of actual reads under this pattern, depending on mode. Brief load should stay under ~80 lines total. Save should read only the sections being touched.

## Failure modes

- **Heading not found:** the section doesn't exist yet. For brain-save, this means appending the heading first; for brain-load, treat the section as empty.
- **Heading appears twice in the file:** a malformed page. Surface the issue to the user — don't guess which heading to read.
- **Section is the last in the file:** there's no "next heading" to bound the read. Use a sensible limit (~50 lines) and accept some over-read.
