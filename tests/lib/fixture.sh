# Fixture helpers, sourced by tests/run.sh and by each case's setup.sh.
# pad_line PREFIX W — print PREFIX padded with 'x' to exactly W bytes INCLUDING the newline.
pad_line() {
  awk -v p="$1" -v w="$2" 'BEGIN { s = p; while (length(s) < w - 1) s = s "x"; print s }'
}
# repeat_lines N PREFIX W — N copies of pad_line PREFIX W.
repeat_lines() {
  _i=0
  while [ "$_i" -lt "$1" ]; do pad_line "$2" "$3"; _i=$((_i + 1)); done
}
# demo_page — the 1444-byte project page used by several cases (same bytes as sections-basic).
demo_page() {
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
  } > pages/Projects___Demo.md
}
