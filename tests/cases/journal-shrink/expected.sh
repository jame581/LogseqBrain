pad_line '  - [[Projects/X]]: two ' 800
pad_line '  - [[Projects/X]]: three ' 500
# The journey-log bullet `brain activity` writes itself is a real mention of the page — it names it
# mid-bullet, so the old "the link must start the bullet" rule made it invisible to `brain journal`.
printf '%s\n' '  - 10:00 saved [[Projects/X]]'
pad_line '  - [[projects/x]]: four, lowercase link ' 700
printf '%s\n' 'coverage: 4 of 5 mentions, 2.0 KB of 3.3 KB journal (journals/2026_09_11.md)'
