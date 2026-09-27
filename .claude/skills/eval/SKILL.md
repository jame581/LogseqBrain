---
name: eval
description: Run the logseq-brain eval suite in WSL2 as the logseq-eval user — free --check by default, a paid full or single-case run only after confirmation. Invoke only when the user asks to run evals.
disable-model-invocation: true
---

# Run the eval suite

`evals/README.md` is the source of truth. Read it before running anything the first time in a session.

## Hard rules

- Run it **only** through WSL2 as the `logseq-eval` user: `wsl -d FedoraLinux-44 -u logseq-eval sh /mnt/d/AI/logseq-brain/tools/eval/run.sh …`. Never run it on native Windows, and never as the Docker-linked user.
- It evaluates **committed** files only. If `git status` shows uncommitted changes to `skills/`, say that they won't be evaluated.
- Run it through PowerShell, or through Bash with single quotes. wsl.exe heredocs halve backslashes.

## Modes

| Ask | Command args | Cost |
|---|---|---|
| default / "check" | `--check` | free: case schema and tool grants |
| harness self-test | run `sh tools/eval/test.sh` locally | free |
| one case | `--case <name>` | paid, a fraction of a full run |
| full | *(no args)* | paid, ≈ $4–7 of plan usage |

Always run `--check` first. Before any paid mode, state the estimated cost and wait for a yes.

## Reading the result

- Exit 0 means every case passed and the canary is clean. A usage-limit error is not a failure; rerun after the limit resets.
- A failed case may be rerun once with `--case <name>`. A pass on the rerun counts as a flake, and a second failure is a real failure.
- Report per-case pass/fail, both canary lines, and the `load-digest` and `save-basic` tool-call figures. Reports land in `evals/results/`, which is gitignored.
