# Two Map lines in one ## Digest — a realistic Logseq Sync conflict artifact. Rewriting the first
# and leaving the second stale, then reporting "map: ok", is exactly the silent wrong figure §5 bans.
{
  printf '%s\n' 'type:: project' 'status:: active' 'last-updated:: 2026-09-10' 'digest-updated:: 2026-09-10' \
    '- ## Digest' '  - Id' '  - Map: Notes | 1 KB · page | 1 KB' '  - Map: Notes | 1 KB · page | 1 KB' '- ## Notes'
  repeat_lines 11 '  - n' 100
} > pages/Projects___Dup.md
