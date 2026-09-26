save_fixture
{ printf '%s\n' 'type:: project' '- ## Digest' '  - Id' '- ## Current Plan'; repeat_lines 90 '  - p' 100
  printf '%s\n' '- ## Session Log'; pad_line '  - 2026-09-01: a' 200; } > pages/Projects___Big.md
