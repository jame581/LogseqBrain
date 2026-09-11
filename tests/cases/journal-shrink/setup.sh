printf '%s\n' 'type:: project' '- ## Overview' '  - x' > pages/Projects___X.md
{
  printf '%s\n' '- ## Sessions'
  pad_line '  - [[Projects/X]]: one ' 600
  pad_line '    - detail ' 400
  pad_line '  - [[Projects/Y]]: other ' 300
  pad_line '  - [[Projects/X]]: two ' 800
  pad_line '  - [[Projects/X]]: three ' 500
  printf '%s\n' '- ## Activity' '  - 10:00 saved [[Projects/X]]'
  pad_line '  - [[projects/x]]: four, lowercase link ' 700
} > journals/2026_09_11.md
