# Cross-Graph Search

When the user says "what do we know about X", "search brain for X", or "find X in brain", search the entire graph for the term and present grouped results.

## Algorithm

1. **Search broadly.** Use Grep to search across all `.md` files in `pages/` and `journals/`. Search the term case-insensitively.

2. **Filter results:**
   - Exclude matches from `logseq/bak/` (backup files).
   - Exclude `logseq/` config files.
   - Keep only matches under `pages/` and `journals/`.

3. **Group by source:**
   - **Project pages** (`pages/Projects___*.md`): show project name + matching section heading.
   - **Journal entries** (`journals/yyyy_MM_dd.md`): show date + a few lines of context.
   - **Meta / Decisions / Index** pages: show the matching entry.

4. **Read context for top matches.** For the 3-5 most relevant matches, read a few lines of surrounding context (offset+limit on the matching line) — don't just show the bare match.

5. **Present findings:**
   - "Found [term] in [N] places:"
   - For each match: source page as a `[[link]]`, section heading, relevant context.
   - If no matches: "Nothing in the brain about [term]. This might be new territory."

## Performance

This is the most expensive read pattern in the plugin. Don't pre-warm by globbing then reading every file — let Grep do the filtering and only Read for top matches.
