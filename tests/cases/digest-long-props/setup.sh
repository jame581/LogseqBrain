{
  i=1; while [ "$i" -le 22 ]; do printf 'key%02d:: v\n' "$i"; i=$((i + 1)); done
  printf '%s\n' 'status:: active' '- ## Digest' '  - Id' '  - Map: page | 1 KB' '- ## Notes' '  - n'
} > pages/Tasks___Long.md
