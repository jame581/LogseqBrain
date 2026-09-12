{
  printf '%s\n' 'status:: active' '- ## Notes'
  repeat_lines 49 '  - a' 100
  pad_line '  - needle' 100
  repeat_lines 50 '  - b' 100
} > pages/Tasks___Big.md
