---
type: regex
target: trace
pattern: 'activity: [^\n\\]*--graph'
match: not_contains
---
No activity bullet carries flag text (v0.11.0 appended `--graph <dir>` to the bullet).
