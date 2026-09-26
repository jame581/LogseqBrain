---
description: 'A configured graph elsewhere never receives the load: the helper honours --graph wherever the model puts it (v0.12.0 spec §5).'
tags: [honesty]
runs: 1
max_turns: 25
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill]
---

load Demo from my Logseq brain. The graph is the folder ./graph in the current working directory; use that folder as the graph path. Before loading, run the brain helper's `info` command once without `--graph` and tell me which graph my own config points at.
