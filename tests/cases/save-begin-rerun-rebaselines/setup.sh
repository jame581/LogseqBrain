save_fixture
printf '%s\n' '- ## Notes' '  - m' > pages/Meta.md
sf_begin Projects/Dig --also pages/Meta.md
printf '%s\n' '  - written after the first save-begin' >> pages/Meta.md
