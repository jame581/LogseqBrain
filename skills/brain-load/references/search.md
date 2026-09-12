# Cross-Graph Search

For "what do we know about X", "search brain for X", "find X in brain".

1. **`brain search "X"`.** It searches `pages/` and `journals/` only, never `logseq/` backups, case-insensitively. It returns hits when there are ≤ 20 of them in ≤ 4 KB, otherwise per-page and per-section counts. Hits from done task pages and session archives are marked `(done task)` / `(archive)`, so say that cold context is cold.
2. **Counts only?** Narrow the term, or scope it: `brain search "X" --page <P> [--section S]`. Pick the page from the counts.
3. **Context for the best hits:** `brain search "X" --page <P> --context 5` (windows capped at 8 KB in total).
4. **Present:** "Found X in N places:", each with its `[[page link]]`, section and context, then the `coverage:` line. No hits: "Nothing in the brain about X — this might be new territory."
