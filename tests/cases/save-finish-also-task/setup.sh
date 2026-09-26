save_fixture
digest_page 'Session Log | 4 KB (2 entries) · Current Plan | 1 KB · +2 smaller sections, 334 B · page | 5 KB' \
  | sed 's/^type:: project$/type:: task/' > pages/Tasks___T-1.md
sf_begin Projects/Dig --also pages/Tasks___T-1.md
sf_add pages/Projects___Dig.md '  - 2026-09-11: c'
sed 's/^status:: active$/status:: done/' pages/Tasks___T-1.md > t.x && mv t.x pages/Tasks___T-1.md
sf_add pages/Tasks___T-1.md '  - 2026-09-11: finished'
