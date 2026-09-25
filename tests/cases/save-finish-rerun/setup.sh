save_fixture
sf_begin Projects/Dig
sf_add pages/Projects___Dig.md '  - 2026-09-11: merged PR #44'
! sh "$BRAIN" --graph "$G" save-finish Projects/Dig --summary 'did c' --index 'v2' > /dev/null || return 1
sed 's/merged PR #44/merged PR 441/' pages/Projects___Dig.md > p.x && mv p.x pages/Projects___Dig.md
