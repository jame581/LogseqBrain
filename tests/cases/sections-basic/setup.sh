f=pages/Projects___Demo.md
{
  printf '%s\n' 'type:: project' 'status:: active' '- ## Digest'
  pad_line '  - Id' 40
  pad_line '  - Map: x' 30
  printf '%s\n' '- ## Overview'
  repeat_lines 3 '  - o' 100
  printf '%s\n' '- ## Session Log'
  pad_line '  - 2026-09-01: a' 200
  pad_line '    - child' 300
  pad_line '  - 2026-09-02: b' 200
  pad_line '    - child' 300
} > "$f"
