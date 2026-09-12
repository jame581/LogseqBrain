# A page whose total lands within 2 bytes of a KiB boundary: the page figure has no fixed point
# ("1023 B" is 2 bytes longer than "1 KB", so the total flips between the two). Before the
# convergence check, --apply wrote a 1024 B file whose Map said "page | 1022 B", then reported
# "map: ok", "0 error, 0 warn", and "unchanged" on a second run.
{
  printf '%s\n' 'type:: project' 'status:: active' 'last-updated:: 2026-09-10' 'digest-updated:: 2026-09-10' \
    '- ## Digest' '  - Map: x' '- ## Notes'
  pad_line '  - n' 863
} > pages/Projects___Kib.md
