# BRAIN_TEST_FAIL_COMMIT truncates the target and then reports failure — the shape of ENOSPC or a
# dropped sync mount. The page must come back byte-identical, not truncated.
printf '%s\n' '- ## Sessions' '  - [[Projects/X]]: worked' '- ## Activity' '  - 09:00 earlier' > journals/2026_09_11.md
