---
name: brain-load
description: >
  Load project context from the Claude Brain Logseq graph into the current session.
  Triggers: "load brain", "load <project>", "resume <project>", "continue work on
  <project>", "what do we know about <topic>". Don't fire for write operations
  (use brain-save), generic questions about Logseq itself, or "open <file>" /
  "switch to <branch>" requests that mean opening files or switching git branches
  rather than loading project memory.
---

# Brain Load

## Running the helper

- Bash: `sh "<this skill's base directory>/../_shared/bin/brain" <command> …`
- PowerShell-only Windows: `& "$(Split-Path (Split-Path (Get-Command git).Source))\bin\bash.exe" "<base>/../_shared/bin/brain" <command> …`
- Neither works: stop and say *"logseq-brain needs Git for Windows (Git Bash) — https://git-scm.com/download/win"*.
- In Cowork, always pass `--graph <connected folder>`. Elsewhere pass `--graph` only when the graph is not configured. It may go anywhere on the line. On exit 2 with `graph not resolved`, follow `skills/_shared/path-resolution.md`, then pass `--graph`.
- Put text arguments in single quotes; a `'` inside becomes `'\''`. In double quotes the shell runs backticks and expands `$`.
- Exit 0 clean, 1 findings (act on them), 2 error (act on its reason; don't retry blindly). Quote every `coverage:` line. Never recompute a figure it printed. Its `graph:` line is the folder for your own Reads.

## Loading a project

1. **One call: `brain load <name>`.** Pass the user's words as they are. The helper accepts `X`, `Projects/X` or `Tasks/X`. Don't list the graph first. On `page not found`, offer its `did you mean:` lines. Only when there are none, follow `references/matching.md`.
2. **Read its blocks:**
   - `map: stale` or `missing`: say so, and state coverage from `computed:`. Loading is read-only: suggest a save, never write.
   - `drift:` over 30 days: suggest a rebuild (`skills/_shared/digest.md`), never unprompted.
   - `staleness:` `aging`: "Note: last updated N days ago." `stale`: "⚠ This project hasn't been updated in N days. Context may be outdated — verify before acting on it." `abandoned`: "This project is marked active but hasn't been touched in N days. Want to update it or mark it paused?" `(no valid last-updated)`: suggest a brain-save to set one. `fresh` and `exempt`: say nothing.
   - `== journal`: today's notes on the page. Quote its coverage line.
   - `digest: missing`: take the **fallback**. `digest: not applicable`: not a project page; read it with bounded `brain read` / `brain tail`.
   - `== activity`: already logged; don't log again.
3. **Stop reading.** Don't pre-load sections, linked pages or task pages. Fetch more only on request, one level at a time, per `skills/_shared/escalation.md`.
4. **Active tasks:** name the task IDs the digest mentions. Never read a task page's body.
5. **Continuity hint:** *"Picking up where you left off — focus: [focus]. Next: [next]. Open: [open]."*
6. **Present, with what was not read.** Give the name, status, staleness, the digest bullets and the hint. Then paraphrase the Map's `label | figure` clauses:
   > Loaded digest for Unicorn-Globus (active, updated 2026-09-07). Focus: … Next: …
   > **Not read:** Session Log 151 KB (62 entries), Decisions 3 KB (3), Current Plan 3 KB, 7 smaller sections. Ask and I'll search any of it.

   Mandatory: a digest shown without what it omits reads as the whole history.

### Fallback: no digest

`brain load` printed the section table. Read, each bounded, each with its coverage:
- Overview's first 5 bullets: `Read` with `offset` = its line in the table, `limit 6`.
- `brain read <page> 'Current Plan'`; over its cap, `brain tail <page> 'Current Plan' --max 8192`.
- `brain tail <page> 'Session Log' --entries 3 --max 4096`.

Build the hint from the newest entry. Then list every section you didn't fetch, with its bytes from the table (mandatory, as in step 6). Log it: `brain activity 'loaded [[Projects/<Name>]] (brief)'`. Offer a digest, quoting the bytes read: *"No digest yet — this load read ~X KB. Build one?"* Build only on yes, via Rebuild in `skills/_shared/digest.md`.

## Full mode ("load <project> full")

`brain load <name> --mode full` prints the section table and `full-budget:`. **Over 24 KB, state it and ask first.** Then run `brain read` on Overview, Current Plan, Implementation and Decisions, and `brain tail <page> 'Session Log' --entries 10 --max 8192`. Report any section refused by its cap. For each task the page references, run `brain digest Tasks/<ID>`, skipping `status:: done`. Linked `[[Projects/…]]` pages likewise get `brain digest` only, never the body. Then log it: `brain activity 'loaded [[Projects/<Name>]] (full)'` (`[[Tasks/<ID>]]` for a task page).

## "load brain"

Read `pages/Index.md` and `pages/Meta.md` (both small). Present active projects, cross-project decisions and preferences. `brain activity 'loaded brain overview'`.

## "what do we know about X"

Follow `references/search.md`, then `brain activity 'searched "X" · N hits'`.

Never Read a whole page.
