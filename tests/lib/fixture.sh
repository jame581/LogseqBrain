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
