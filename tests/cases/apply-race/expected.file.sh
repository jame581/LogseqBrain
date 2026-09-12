# The only change to the page must be the one the BRAIN_TEST_MUTATE_BEFORE_COMMIT hook makes
# (one trailing space, simulating a concurrent writer) — the refusal must write no Map line.
digest_page 'Session Log | 3 KB (2 entries) · Current Plan | 1 KB · +2 smaller sections, 334 B · page | 5 KB'
printf ' '
