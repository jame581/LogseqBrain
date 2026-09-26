save_fixture
sf_begin Projects/Dig
sf_add pages/Projects___Dig.md '  - 2026-09-11: c'
{ sed '/^  - Id$/q' pages/Projects___Dig.md | sed '$d'; pad_line '  - Id ' 900; sed '1,/^  - Id$/d' pages/Projects___Dig.md; } > p.x && mv p.x pages/Projects___Dig.md
