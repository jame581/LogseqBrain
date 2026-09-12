# The link sits mid-bullet, not at its start: this used to report "no mention of [[Projects/Zed]]".
printf '%s\n' 'type:: project' '- ## Overview' '  - x' > pages/Projects___Zed.md
printf '%s\n' '- ## Sessions' '  - Worked on [[Projects/Zed]] today' '    - detail' > journals/2026_09_11.md
