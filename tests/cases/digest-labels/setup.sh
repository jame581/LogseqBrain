{
  printf '%s\n' 'type:: task' '- ## Digest' '  - Id'
  printf '%s\n' '- ## 2026-04-23 Deployment step three ended — with a note'
  repeat_lines 11 '  - a' 100
  printf '%s\n' '- ## 2026-04-23 — Step 2 isolated, real root cause found'
  repeat_lines 11 '  - b' 100
  printf '%s\n' '- ## 2026-04-23 — Step 2 isolated, real root cause fixed'
  repeat_lines 12 '  - c' 100
} > pages/Tasks___Labels.md
