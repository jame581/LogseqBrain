save_fixture
{
  printf '%s\n' 'type:: project' 'status:: active' 'last-updated:: 2026-09-10' 'digest-updated:: 2026-09-10' \
    '- ## Digest' '  - Map: x' '- ## Notes'
  pad_line '  - n' 863
} > pages/Projects___Kib.md
sf_begin Projects/Kib
