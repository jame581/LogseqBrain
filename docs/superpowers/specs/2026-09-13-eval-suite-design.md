# logseq-brain eval suite — design

**Date:** 2026-09-13 · **Status:** approved design, not yet implemented · **Plugin under test:** v0.11.0 (`7cd2fc1`)
**Related:** `docs/superpowers/specs/2026-09-11-v0.11.0-design.md` §8 (the success criteria this suite measures)

---

## 1. Purpose

A local `claude plugin eval` suite that proves four things about the logseq-brain skills, which the golden tests (`tests/run.sh`) cannot, because they test the helper and not the model following the skill prose:

1. **The pending success figures** — tool calls per digest load (target ≤ 4) and per save (≤ 13), and zero new error-tier findings per save — measured on a controlled graph instead of waiting two weeks of real use.
2. **Skills fire correctly** — each request fires the right skill, near-misses fire the wrong one never, and unrelated requests fire none.
3. **Behaviour is honest** — loads state what they did not read, saves write no phantom-page syntax, a digest-less page gets a digest *offered* rather than built, and report-mode doctor writes nothing.
4. **A release regression gate** — rerun before every release, so a skill-prose change that breaks behaviour fails loudly.

**Constraints chosen by the maintainer:**
- **Budget:** lean — about ten cases, one run each, no no-plugin baseline, a hard cost ceiling.
- **Model:** the maintainer's usual model, pinned explicitly.
- **Where it runs:** locally only.

---

## 2. Verified facts this design rests on

Established on 2026-09-13 from the documentation (`code.claude.com/docs/en/plugin-evals.md`, `sandboxing.md`, `setup.md`, `authentication.md`) and two live probes on Claude Code 2.1.270. Anything marked *empirical* is not documented and must be re-verified when Claude Code updates.

| Fact | Source |
|---|---|
| Eval runs, judge graders and `eval init` count against the plan's usage limits (or an API bill). Charges above the plan are not documented. | docs |
| The Bash sandbox runs on macOS, Linux and WSL2. **Native Windows is not supported**: a Bash-granting eval run there is refused (score 0), never run unconfined. | docs |
| The sandbox refuses to run while the Docker credential store (`~/.docker`) contains a symlink — Docker Desktop's WSL integration creates one. | probe 1 (first attempt, $0) |
| Each run gets a throwaway home, working directory and Claude Code config, and runs as a `claude -p` child with only the plugin loaded. | docs |
| Only an environment allowlist plus `EVAL_*` variables reach a run. `LOGSEQ_BRAIN_PATH` was `unset` inside the run. | docs + probe 1 |
| Bash writes outside the workspace fail with `No such file or directory` — outside paths are hidden, on WSL `/tmp` and on the `/mnt/c` Windows mount alike. | probe 1, empirical |
| Write and Read outside the workspace are denied (`running in don't ask mode`); Edit outside it changed nothing. | probe 1, **empirical — Write/Edit confinement is not documented** |
| Sentinels proven writable by the eval user outside the sandbox were unchanged after the run, so the refusals came from the sandbox, not file permissions. | probe 1 |
| A scaffold script runs as the eval user **outside** the sandbox, with cwd = the run workspace (`<tmp>/home/cwd`) and a throwaway `HOME`. | docs + probe 1 |
| `context.add_dirs` grants read-only access; writable fixtures must be copied into the workspace. | docs |
| `--keep-temp` keeps `out/trace.jsonl`, and the `--json` result names it as `tracePath`. Its `tool_use` entries matched the run's tool calls exactly. | probe 1 |
| Per-case `allowed_tools` grants only read-only tools. Bash, Write and Edit need `--allow-tools` on the command line. | docs |
| `max_turns` defaults to 10; a real v0.11.0 save took 15 tool calls. | docs + live save |
| The plugin's helper runs inside the sandbox. With no env var or config, `brain info` exits 2 and the skill passes the prompt's inline graph path as `--graph` (`graph-source: flag`). | probe 2 |
| Every sandboxed Bash call prints `/bin/bash: …/.bashrc: Permission denied` (the throwaway home's `.bashrc` is sealed). | probes 1 and 2 |
| Thin fixtures cause honest exit-2 helper errors (`page not found: Decisions`, `no unique section`) unrelated to the plugin. | probe 2 |
| Cost evidence: a ~10-tool-call run on the usual model cost ≈ $0.25–0.30 list price and took 38–45 s. | probes 1 and 2 |

---

## 3. Architecture

### 3.1 Where it lives
- **Cases:** `evals/<case>/` at the repo root, beside `tests/` and `tools/`.
- **Shared fixtures:** `evals/fixtures/`.
- **Results:** `evals/results/`, gitignored — reports and traces hold full transcripts.
- **Never shipped:** the `.plugin` archive and the marketplace carry only `.claude-plugin`, `skills` and `README.md`.

### 3.2 Where it runs
Only inside WSL2, only as the dedicated user **`logseq-eval`**:
- no sudo;
- no `~/.docker`;
- its own Claude Code install and subscription login.

It never runs as the maintainer's WSL user (Docker symlink) or on native Windows (refused).

### 3.3 What it tests
The wrapper (§8) exports the **committed** `.claude-plugin`, `skills` and `evals` into a fresh directory in the eval user's home, and evaluates that copy. Consequences:
- the agent under test cannot read `tests/`, `docs/` or this spec;
- uncommitted edits cannot leak into a release gate;
- results never land in the Windows repo by accident — the wrapper copies the summary back deliberately.

### 3.4 Fixed flags on every run

```
claude plugin eval <copy> --runs 1 --ablation none --scaffold \
  --allow-tools Bash Write Edit --keep-temp --no-publish --trust-plugin \
  --max-cost-usd 10 --model claude-opus-5 --json <results>/result.json
```

- **`--scaffold`** runs only our own scaffold scripts (§5).
- **`--trust-plugin`** is correct because we author both the plugin and the suite.
- **`--model`** is pinned explicitly, so a changed default cannot silently shift the figures.

### 3.5 Isolation canary
Case 0 re-proves confinement on every run, because Write/Edit confinement is empirical, not documented. The wrapper creates sentinel files outside the workspace **before** the run and checks them from outside **after** it. Any change fails the whole run, whatever the grader scores.

---

## 4. Cases

Every case except `no-trigger` runs against a scaffold-made graph at `./graph` and names that path inline. An eval run cannot answer a question, so each prompt pre-answers the questions that **its own** skill would ask, in the direction that case asserts. There is deliberately no global "assume yes":
- `save-basic` and `init-project` say "if you would ask me anything, assume yes";
- `load-no-digest` says "just load it — do not build or change anything";
- `doctor-report-only` says "report only — do not fix anything".

A blanket "yes" would make those last two cases build and fix, and fail by design. Cases avoid decision-shaped wording unless a decision is the point, so brain-save's decision prompt cannot stall a run.

| # | Case | Goal | Asserts — beyond "the right skill fired" |
|---|---|---|---|
| 0 | `isolation-canary` | safety | Bash, Write and Edit cannot change the sentinels; `LOGSEQ_BRAIN_PATH` is unset. Checked by the wrapper from outside. |
| 1 | `load-digest` | figures, honesty | `load Demo` on a digest-bearing page: tool calls ≤ 4 (reported); no Read of the page file; the reply states what it did not read; the `(digest)` activity line is written |
| 2 | `load-no-digest` | honesty | `load Legacy` (no digest): coverage stated; a digest is offered, not built — the page file still has no `## Digest` |
| 3 | `save-basic` | figures | a progress-only save to Demo: tool calls ≤ 13 (reported); a new Session Log entry; `brain check` ran with 0 new errors; the `saved` activity line |
| 4 | `save-phantom-syntax` | honesty | save text containing a bare `#12`, `C#-parity` and PR `#44`: `brain check` **never** reports a new error on the page |
| 5 | `status-dashboard` | triggering | "what's in my brain": brain-status fires and brain-load does not; exactly one `brain status` call; the counts line is printed |
| 6 | `search-scoped` | honesty | "what do we know about the export feature": a count-first `brain search` for `export`, a term the base fixture plants in several sections of Demo and in `Decisions.md`; no whole-page Read; coverage stated |
| 7 | `doctor-report-only` | honesty | `brain doctor` on a graph with a bare `#44`: the finding is reported; no Write and no Edit call at all |
| 8 | `init-project` | triggering | `init brain project Scratch`: the page is created and its `- Map:` line is computed, not `pending` |
| 9 | `no-trigger` | triggering | an unrelated request fires no `brain-` skill; no graph is scaffolded |

**Bounds per case:**
- `max_turns: 40` for saves and init, `25` elsewhere;
- `timeout_seconds: 300`;
- `runs: 1`.

---

## 5. Fixtures and scaffolds

### 5.1 Base fixture — `evals/fixtures/base-graph/`
One complete small graph shared by all graph-using cases:
- **`pages/Index.md`, `pages/Meta.md`, and `pages/Decisions.md`** with a `## Decision Log` entry.
- **`pages/Projects___Demo.md`**, digest-bearing, with properties and every standard section (`## Digest`, `## Overview`, `## Current Plan`, `## Implementation`, `## Decisions`, `## Session Log`). Its Session Log is large enough (≥ 1 KiB) to give the Map a real candidate. Its committed Map line is **generated from a date-substituted copy** with `brain digest --apply`, then written back into the tokenized fixture. The helper recognizes Session Log entries only by real `yyyy-MM-dd` dates, so a Map computed on `@TODAY-NN@` tokens would carry wrong entry counts. The Map line itself contains no dates, so it survives the round trip exactly.
- **`pages/Projects___Legacy.md`**: project properties and sections, **no** `## Digest`.
- **`pages/Tasks___DEMO-1.md`** with `status:: active`.
- **One earlier journal, and a minimal `logseq/config.edn`.**

### 5.2 Overlays
A case needing extra content carries `evals/<case>/overlay/`, copied over the base. For example, `doctor-report-only` adds a page containing a bare `#44`.

### 5.3 Scaffold contract
Each case's `scaffold.sh` is a few lines and **must**:
- copy the base graph into `./graph`;
- apply its overlay;
- substitute date tokens (§5.4);
- locate the fixture relative to its own path, and exit non-zero with a clear message if the fixture is not found;
- never write outside its working directory.

It is the only suite code that runs outside the sandbox, so it stays that small.

### 5.4 Dates do not rot
Fixture dates are written as **10-byte tokens** `@TODAY-NN@` (e.g. `@TODAY-03@` = three days ago). The scaffold replaces each with a `yyyy-MM-dd` date, also 10 bytes, computed from today. Consequences:
- **Figures stay exact:** byte counts are unchanged, so the committed Map line stays exact.
- **Staleness does not drift:** "fresh" stays fresh forever.
- **Filenames use the same idea:** journal filenames use `@TODAY_NN@` and are renamed to `yyyy_MM_dd`.

### 5.5 Fixture validity is checked for free
`tests/run.sh` gains a golden case that date-substitutes a copy of the base fixture and asserts:
- `brain lint --all` is clean;
- `brain digest Projects/Demo` reports `map: ok`.

A helper change that invalidates the fixture then fails in CI on five awk builds, instead of silently spoiling a paid eval run.

---

## 6. Graders

Deterministic graders only, so they cost nothing. The one exception is allowed in §6.3.

### 6.1 Grader kinds

| Check | Grader |
|---|---|
| Right skill fired / wrong one did not | `tool_used` on `Skill`, `input_match` on the skill name (`min: 1`, or `max: 0` for a must-not-fire skill; `no-trigger` matches any `brain-` skill) |
| A helper command ran (and how often) | `tool_used` on `Bash`, `input_match` on the `brain` subcommand in the JSON-encoded input |
| No forbidden reads or writes | `tool_used` with `max: 0` (Read of a page file; any Write or Edit in `doctor-report-only`) |
| File contents after the run | `regex` with `target: { source: file, path: graph/pages/… }` (`match: not_contains` where absence is the assertion) |
| What the helper printed | `regex` with `target: trace` (activity lines, the status counts line, `check` results) |

### 6.2 Three rules that keep graders truthful
1. **Journal assertions read the trace, not the file.** The journal filename is today's date, unknown when a case is written. The helper prints `activity: HH:MM <line> → journals/…`, which carries no date.
2. **Phantom syntax is graded as "never written".** A grader that looks for a clean `brain check` passes even if the save wrote `#12` bare, was caught, and fixed it. `save-phantom-syntax` instead asserts, with `match: not_contains`, that the trace holds **no** `check pages/Projects___Demo.md: <N> new (<E> error` line with `E ≥ 1`. That tests the compose-time rule, not the backstop.
3. **Patterns never anchor to line starts,** so the sandbox's `.bashrc: Permission denied` noise cannot break them.

### 6.3 The coverage statement
"States what it did not read" uses a `regex` on `last_message` with `flags: i` for the skill's mandated `Not read` statement. If the wording proves too varied in practice, **that grader alone** becomes a Haiku-judged `llm` rubric. No other grader may call a judge.

### 6.4 Scoring
Each case's score is its weighted grader pass fraction. The suite uses the default `--threshold 1.0`, so any failing grader fails the run.

---

## 7. Measurement

- **Tool calls per run** = the number of `"type":"tool_use"` entries in that run's `out/trace.jsonl`, the Skill call included. That is the same definition `tools/measure/cost.py` uses, so eval figures compare with the real-use baseline.
- **Every run prints a table:** per case, pass/fail, tool calls, cost and duration.
- **Targets:** `load-digest` is compared against ≤ 4 and `save-basic` against ≤ 13.
- **Figures are reported, never gating.** With one run per case each figure is one sample, so an over-target count is flagged in the table and recorded, but does not change the exit code. "0 new error-tier findings per save" **is** gated, by the graders of cases 3 and 4.

---

## 8. The wrapper — `tools/eval/run.sh`

POSIX `sh`, dev-only. Invoked from Windows as:

```
wsl -d FedoraLinux-44 -u logseq-eval sh /mnt/d/AI/logseq-brain/tools/eval/run.sh [--case <glob>]
```

Steps, in order:
1. **Refuse to start** unless running as `logseq-eval`, on Linux, with Claude Code ≥ 2.1.269.
2. **Export the committed payload** — `.claude-plugin`, `skills` and `evals` (excluding `results/`) — from the repo's `HEAD` into a fresh directory in the eval user's home.
3. **Create the canary sentinels** outside the workspace, on WSL `/tmp` and on a Windows-drive mount. Pass their locations to the run as `EVAL_*` variables, which the canary's scaffold writes into the workspace for the prompt to read.
4. **Run `claude plugin eval`** with the §3.4 flags, passing `--case` through.
5. **Check the sentinels from outside.** Any change → fail the run with a clear message.
6. **Count tool calls** from each run's trace and print the §7 table.
7. **Copy** `result.json`, the summary table and the traces into the repo's `evals/results/<timestamp>/`.
8. **Remove** the exported copy, the kept temp directories and the sentinels.

**Exit code:** non-zero if any grader failed or the canary tripped; zero otherwise.

**Cost:** ≈ $4–7 list price per full run on the usual model, under the $10 ceiling, drawn from the plan's usage limits. `--case` reruns a single case cheaply.

---

## 9. Repository integration

- **`.gitignore`:** add `evals/results/`.
- **`evals/README.md`:**
  - one-time setup — create the WSL user, install Claude Code, log in;
  - running the suite;
  - adding a case;
  - the facts in §2, including the two traps: native Windows refuses Bash runs, and a Docker symlink blocks the sandbox;
  - why the canary exists.
- **`CONTRIBUTING.md` release checklist:** a new step — run the eval suite; all cases pass, canary clean; record the figures in the release notes. It is local only; CI keeps running the golden tests.
- **`CLAUDE.md` "Working in this repo":** one line — run the suite before releases and after changing skill prose; it requires `logseq-eval` in WSL2.
- **Branch and version:** branch `eval-suite`, merged by PR. **No plugin version bump**: nothing that ships changes.

---

## 10. Out of scope

- Running evals in CI (needs an API key billed separately, and a Linux runner with a login).
- The no-plugin baseline arm, and multi-run statistics.
- `llm` judges beyond the §6.3 fallback.
- Rotation, digest backfill, `brain-doctor` repair mode, and cross-project decisions — each needs multi-step interactive confirmation that a `claude -p` run cannot give.
- Comparing models.

---

## 11. Verify first in the implementation plan

Each item is cheap to settle, and each would otherwise surface as a confusing case failure.

1. **Fixture location from `$0`.** The scaffold locates its fixture relative to its own path. Confirm the harness invokes it by its real path; if not, fall back to fixtures embedded in the scaffold.
2. **`EVAL_*` variables** set by the wrapper reach both the scaffold and the run.
3. **`--model claude-opus-5`** is accepted by `claude plugin eval`.
4. **Exporting `HEAD` as `logseq-eval`** from the Windows-owned repo on `/mnt/d` works (`git -c safe.directory=… archive`), or a committed-tree copy replaces it.
5. **The exact `input_match` escaping** for a `brain` subcommand inside JSON-encoded Bash input.
6. **The §6.3 regex** matches the coverage statement brain-load actually produces.
7. **The Windows-drive sentinel location.** The canary needs a directory on a Windows mount that the eval user can write outside the sandbox. The Windows username is machine-specific, so derive the location rather than hard-code it: resolve `%TEMP%` through WSL interop (`cmd.exe /c echo %TEMP%`, then `wslpath`), with an `EVAL_CANARY_WINDIR` override. If neither works, the canary runs on `/tmp` alone and the summary states that the Windows-mount half was skipped — never silently.

---

## 12. Probe cleanup

**Remove:**
- `~/eval-probe` for both WSL users, and `~/eval-probe2`;
- kept `/tmp/claude-eval-*` directories;
- all probe sentinels on `/tmp` and under the Windows `%TEMP%`.

**Keep:** the `logseq-eval` user, which the suite needs, and the probe-1 trace copy until the tool-call counter is written.
