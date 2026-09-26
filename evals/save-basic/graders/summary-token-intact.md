---
type: regex
target: trace
pattern: 'sessions: \[\[Projects/Demo\]\]: [^\n\\]*`uploadCsv\(\)`'
---
The backticked identifier reached the `## Sessions` bullet intact through `save-finish --summary`: the
skill quoted the text in single quotes, so the shell did not run the backticks (v0.12.0 plan Task 14 Step 5).
