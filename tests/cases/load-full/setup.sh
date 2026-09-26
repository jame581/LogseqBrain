# Section bodies: Overview 300 B, Current Plan 1100 B, Implementation 9000 B (capped at 8192),
# Decisions 200 B, Session Log 12 x 1024 = 12288 B (capped at 8192): full-budget 17984 B.
{
  printf '%s\n' 'type:: project' '- ## Digest' '  - Id' '- ## Overview'
  repeat_lines 3 '  - o' 100
  printf '%s\n' '- ## Current Plan'
  repeat_lines 11 '  - p' 100
  printf '%s\n' '- ## Implementation'
  repeat_lines 90 '  - i' 100
  printf '%s\n' '- ## Decisions'
  repeat_lines 2 '  - d' 100
  printf '%s\n' '- ## Session Log'
  for d in 01 02 03 04 05 06 07 08 09 10 11 12; do pad_line "  - 2026-09-$d: e" 1024; done
} > pages/Projects___Full.md
