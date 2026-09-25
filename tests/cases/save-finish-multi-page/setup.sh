save_fixture
digest_page 'Session Log | 4 KB (2 entries) · Current Plan | 1 KB · +2 smaller sections, 334 B · page | 5 KB' > pages/Projects___Y.md
sf_begin Projects/Y
sf_add pages/Projects___Y.md '  - 2026-09-11: y'
sh "$BRAIN" --graph "$G" save-finish Projects/Y --summary 'did y' > /dev/null || return 1
sf_begin Projects/Dig
sf_add pages/Projects___Dig.md '  - 2026-09-11: c'
