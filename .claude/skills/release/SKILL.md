---
name: release
description: Cut a logseq-brain release — eval gate, version bump in plugin.json and BRAIN_VERSION, tag, GitHub release, .plugin rebuild, skillsmith marketplace bump. Invoke only when the user asks to release.
disable-model-invocation: true
---

# Release logseq-brain

`CONTRIBUTING.md` § Releasing a new version is the source of truth. Read it now, in full, and follow it step by step. This skill only adds the order of operations and the checks that have slipped before.

Argument: the version `X.Y.Z`. If none was given, read `.claude-plugin/plugin.json` and `ROADMAP.md` and ask which version to cut.

## Before step 0

- The version branch `vX.Y.Z` is merged to `main` by PR, and the local `main` is pulled. Releases are cut from `main`.
- `git status` is clean.

## Gates — stop and report on any failure

1. The `tests` workflow is green on the release commit: `gh run list --branch main --limit 3`.
2. The eval suite passes on the release commit. It runs only as the `logseq-eval` WSL user and draws on plan usage, so **ask before launching it**. Use the `/eval` skill. Record the `load-digest` and `save-basic` tool-call figures for the release notes.

## Mechanical steps

- Bump **both** `.claude-plugin/plugin.json` `"version"` and `BRAIN_VERSION` in `skills/_shared/bin/brain`. The `version-matches-plugin` golden case fails until they agree, so run `sh tests/run.sh 'version-*'`.
- Annotate the version's design spec with the release measurement if the spec calls for it. Never rewrite the spec body.
- Commit with `chore(release): prepare vX.Y.Z`, then tag it annotated and push the tag. **Confirm with the user before pushing.**
- Create the GitHub release (`gh release create vX.Y.Z --notes-file …`). Draft the notes from the commits since the previous tag, and include the eval figures.

## After the tag — the steps that get forgotten

- Rebuild the Cowork archive from the tag and verify the listing: it must contain `skills/_shared/bin/brain` and `skills/_shared/lib/core.awk`, and must **not** contain `tests/` or `tools/`.
- Bump `.claude-plugin/marketplace.json` in the sibling `../skillsmith` repo. First run `git -C ../skillsmith pull`, and never assert its state from memory. That repo has its own commit and push. Confirm before pushing.
- Update the logseq-brain project page in the brain with the release (`/brain-save`).

End with a checklist that shows each step as done, skipped (and why), or blocked.
