---
type: regex
target: trace
pattern: 'check (?:pages|journals)/(?!Projects___X\.md)[^:\s]+\.md: \d+ new \((?:[1-9]\d* error|\d+ error, \d+ warn\), \d+ pre-existing.{1,12}digest: [1-9]\d* error)'
match: not_contains
---
