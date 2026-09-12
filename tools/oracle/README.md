# Transit oracle (dev-only)

`brain lint` must flag exactly the text that Logseq OG turns into pages. This tool checks that against Logseq's own parse cache instead of a guess about the parser.

    python tools/oracle/oracle.py --graph /path/to/ClaudeBrain

Spell the path the way Logseq stored it — forward slashes, no trailing slash (on Windows, e.g. `--graph C:/Users/you/ClaudeBrain`) — so the transit cache filename resolves; otherwise pass `--transit` explicitly.

Run it before any release that touches `skills/_shared/lib/lint.awk`. Open the graph in Logseq first so the cache is current.

**Fixture graph.** Copy `fixture-graph/` somewhere outside the repo, add it in Logseq desktop (Add graph), let it index, close Logseq, then run the oracle with `--graph <copy>`. The `Probes` bullet settles which of `. ; : ! ? '` start a tag. A `MISSED:` line for one of them means `lint.awk`'s exclusion list is wrong for that character: remove it from the `index(" \t#[]`,\"*.;:!?'", nx)` string, add a `lint-tags` case line, and update `bare-hash-tag` in `skills/_shared/hygiene-rules.md`.

**Known limitation.** Phantom pages under `tasks/` and `projects/` are excluded from the comparison as legitimate forward references (a task or project page it's fine to link to before it exists), so a mistyped namespaced tag or link — e.g. `#tasks/broken` or `[[Tasks/Borken]]` — will not be caught by the oracle. That filter is intentional and out of scope for this tool; it is not something to "fix" in the comparison logic.
