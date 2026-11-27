# An --also file deleted after save-begin is reported, and the save still completes.
save_fixture
printf '%s\n' '- ## Decision Log' '  - d' > pages/Decisions.md
sf_begin Projects/Dig --also pages/Decisions.md
rm pages/Decisions.md
