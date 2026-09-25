---
type: regex
target: trace
pattern: 'uploadCsv\(\)?: command not found|command not found: uploadCsv'
match: not_contains
---
A double-quoted text argument would make the shell run `uploadCsv()` as a command.
