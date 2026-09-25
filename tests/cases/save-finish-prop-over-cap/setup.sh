save_fixture
sf_begin Projects/Dig
sf_add pages/Projects___Dig.md '  - 2026-09-11: c'
{ sed -n '1,/^next:: /p' pages/Projects___Dig.md; pad_line 'open:: ' 158; sed '1,/^next:: /d' pages/Projects___Dig.md; } > p.x && mv p.x pages/Projects___Dig.md
