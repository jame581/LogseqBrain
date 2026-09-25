# Fixture helpers, sourced by tests/run.sh and by each case's setup.sh.
# pad_line PREFIX W — print PREFIX padded with 'x' to exactly W bytes INCLUDING the newline.
pad_line() {
  awk -v BINMODE=3 -v p="$1" -v w="$2" 'BEGIN { s = p; while (length(s) < w - 1) s = s "x"; print s }'
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

# digest_page MAPTEXT|- — print the Digest test page (5717 B + the Map line) to stdout. "-" = no Map line.
# Callers redirect: `digest_page '...' > pages/Projects___Dig.md`.
digest_page() {
  {
    printf '%s\n' 'type:: project' 'status:: active' 'last-updated:: 2026-09-10' 'focus:: f' \
      'next:: n' 'digest-updated:: 2026-09-10' '- ## Digest' '  - Id'
    [ "$1" != - ] && printf '  - Map: %s\n' "$1"
    printf '%s\n' '- ## Overview'
    repeat_lines 3 '  - o' 100
    printf '%s\n' '- ## Current Plan'
    repeat_lines 11 '  - p' 100
    printf '%s\n' '- ## Session Log'
    pad_line '  - 2026-09-01: a' 1000
    pad_line '    - c' 1048
    pad_line '  - 2026-09-02: b' 1000
    pad_line '    - c' 1048
    printf '%s\n' '- ## Decisions' '  - _Project-specific decisions._'
  }
}

# save_fixture — Projects/Dig (digest-ok's page), a pages/Index.md whose ## Projects lists it at line 4
# (Quick Links mentions it too, and line 5 mentions it only as a second link), and today's journal with
# ## Sessions (last line 2) and ## Activity. Run from the graph root.
save_fixture() {
  digest_page 'Session Log | 4 KB (2 entries) · Current Plan | 1 KB · +2 smaller sections, 334 B · page | 5 KB' > pages/Projects___Dig.md
  printf '%s\n' '- ## Quick Links' '  - [[Projects/Dig]] quick' '- ## Projects' \
    '  - [[Projects/Dig]] — test page (v1 — digest)' '  - [[Projects/Other]] — other, see [[Projects/Dig]]' > pages/Index.md
  printf '%s\n' '- ## Sessions' '  - [[Projects/Other]]: x' '- ## Activity' '  - 09:00 y' > journals/2026_09_11.md
}
# sb_block NAME — the lines of block "== NAME" in $RUN/out, without its header (for post.sh).
sb_block() { awk -v b="== $1" '$0 == b { on = 1; next } /^== / { on = 0 } on' "$RUN/out"; }
# sb_manifest — the one save manifest under this case's TMPDIR, or nothing.
sb_manifest() { find "$TMPDIR/logseq-brain" -name 'save.*.lst' -type f 2>/dev/null; }
