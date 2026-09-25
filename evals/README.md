# logseq-brain eval suite

`claude plugin eval` cases that test the skills — the model following the skill prose — against a controlled fixture graph.

The golden tests in `tests/` cover the helper. This suite covers what they cannot:
- the right skill fires;
- loads and saves stay within their tool-call budgets;
- the skills behave honestly: coverage statements, no phantom-page syntax, and report-only means report only.

Design: [`docs/superpowers/specs/2026-09-13-eval-suite-design.md`](../docs/superpowers/specs/2026-09-13-eval-suite-design.md).

**Every run draws on real usage.** Eval runs count against your Claude plan's usage limits (or an API bill). A full run is roughly $4–7 at list price, capped at $10 per invocation. Nothing here runs in CI.

## Where it runs, and why

- **WSL2 or Linux only.** A run that grants Bash needs Claude Code's OS sandbox. Native Windows has none, so the harness refuses the run (score 0) rather than run it unconfined.
- **As a dedicated user, `logseq-eval`.** The sandbox refuses to start while `~/.docker` contains a symlink, and Docker Desktop's WSL integration creates one for your normal user. A separate user avoids that without weakening the check. It has no `~/.docker`, no sudo, and its own Claude login. Never work around the check with `DOCKER_CONFIG`.
- **Against the committed plugin.** The wrapper exports `HEAD`'s `.claude-plugin`, `skills` and `evals` to a temporary copy, so uncommitted edits are never evaluated. Commit first.

## One-time setup

From Windows, adjusting the distro name:

```
wsl -d FedoraLinux-44 -u root useradd -m logseq-eval
wsl -d FedoraLinux-44 -u root dnf install -y bubblewrap socat git python3
wsl -d FedoraLinux-44 -u logseq-eval
```

In that shell, install Claude Code with the native installer ([setup docs](https://code.claude.com/docs/en/setup)). Then run `claude` once to log in with your subscription.

## Running

```
wsl -d FedoraLinux-44 sh /mnt/d/AI/logseq-brain/tools/eval/test.sh                                 # free: tools, case regexes, scaffolds
wsl -d FedoraLinux-44 -u logseq-eval sh /mnt/d/AI/logseq-brain/tools/eval/run.sh --check           # free: case schema and tool grants
wsl -d FedoraLinux-44 -u logseq-eval sh /mnt/d/AI/logseq-brain/tools/eval/run.sh                   # the whole suite
wsl -d FedoraLinux-44 -u logseq-eval sh /mnt/d/AI/logseq-brain/tools/eval/run.sh --case load-digest  # one case (a name glob)
wsl -d FedoraLinux-44 -u logseq-eval sh /mnt/d/AI/logseq-brain/tools/eval/run.sh --dry-run         # free: every step but the harness
wsl -d FedoraLinux-44 -u logseq-eval sh /mnt/d/AI/logseq-brain/tools/eval/run.sh --trip-canary     # free: proves the canary check fires (exit 3)
```

Adjust the repository path to your checkout.

From Git Bash:
- prefix `MSYS_NO_PATHCONV=1`, or Git Bash rewrites the `/mnt/...` path;
- call `wsl.exe … -e sh …`, so no shell expands a `--case` glob.

**Passing a variable.** `wsl` does not hand your shell's variables to the Linux side (unless they are listed in `WSLENV`), so set them inside with `env`:

```
wsl -d FedoraLinux-44 -u logseq-eval -e env EVAL_CANARY_WINDIR=/mnt/c/Users/<you>/AppData/Local/Temp sh /mnt/d/AI/logseq-brain/tools/eval/run.sh
```

**Run one invocation at a time.** Each invocation removes the harness's `/tmp/claude-eval-*` run directories created since it started, so two invocations running at once delete each other's run directories and traces. There is no lock.

**What the wrapper prints.** A table with a row per case: pass/fail, tool calls, the target for the two measured cases, cost and time.
- Tool calls are counted from the first `brain-` Skill call onward, as `tools/measure/cost.py` counts them.
- The targets (`load-digest` ≤ 4, `save-basic` ≤ 13) are **pass criteria** since v0.12.0 (spec `2026-09-25-v0.12.0-design.md` §5). An over-target run is flagged `OVER`, listed with the failures, and fails its case. `claude plugin eval` has no grader that counts every tool call, so `tools/eval/summarize.py` applies the gate. One run per case is one sample: before changing prose over a single `OVER`, run `python3 tools/eval/summarize.py breakdown <trace>` to see where the calls went.
- Since v0.12.0 the routine shapes are 2 calls (`load-digest`: Skill, `brain load`) and 7 (`save-basic`: Skill, `save-begin`, one Read, three Edits, `save-finish`).

**Where results go.** The summary, the harness's JSON and HTML report, and each run's trace go to `evals/results/<timestamp>/`. An interrupted run (HUP, INT or TERM) keeps what the harness wrote in `<timestamp>-partial/`, with a `canary.txt` that compares the sentinels before they are deleted. The directory is gitignored because traces are full transcripts.

**Exit codes:**

| Code | Meaning |
|---|---|
| 0 | Every case passed (or `--check` clean), and the canary is clean |
| 1 | A case failed (or `--check` found problems) |
| 2 | Refused (a full run whose Windows canary half cannot run included), a partial or interrupted run, or an environment error |
| 3 | The canary tripped. Outranks every other code, an interrupted run included |

**When a case fails:**
1. **Check the run errors in the summary first.** Hitting your plan's usage limit or a rate limit mid-suite makes every later run end with that error and score about 0, and the run is not marked partial. Rerun after the limit resets.
2. **Read the case's trace** in `traces/` before touching a grader. A grader that failed because the skill misbehaved is a finding about the skill, not a grader bug: never weaken the grader.
3. **Before a release,** a failed case may be rerun once with `--case <name>`. If the rerun passes, record both results in the release notes as a flake. A second failure blocks the release, and a tripped canary always does.

## The isolation canary

That the sandbox confines Write and Edit is not documented: it was verified by probe on Claude Code 2.1.270. So every run re-proves it:
1. **Before the suite,** the wrapper creates sentinel files outside the workspace, on `/tmp` and on the Windows `%TEMP%` mount. It passes their paths to the run as `EVAL_CANARY_TMP` and `EVAL_CANARY_WIN`.
2. **During the suite,** `isolation-canary` tries to change them with Bash, Write and Edit.
3. **Afterwards,** the wrapper checks them from outside. Any change exits 3, whatever the graders scored.

A `--case` run that does not select `isolation-canary` still checks the sentinels, but nothing in it tries to change them, so its summary says `confinement NOT re-proven`. Only a run in which `isolation-canary` attempted the writes and passed prints `confinement re-proven`.

**If the Windows half cannot run.** The wrapper finds `%TEMP%` by running `cmd.exe`, which needs WSL interop. After a WSL VM restart interop can break (`cmd.exe: cannot execute binary file: Exec format error`). A full run, or its `--dry-run`, then refuses with exit 2 before the harness starts, so the refusal costs nothing. The message names the cause, `cmd.exe could not run (WSL interop unavailable)` or `no writable Windows directory`, and the ways out:
- run `wsl --shutdown` from Windows; interop works again at the next start;
- or set `EVAL_CANARY_WINDIR` to a Windows-mount directory that `logseq-eval` can write, with `env` as shown under Running;
- or set `EVAL_CANARY_SKIP_WIN=1` to run with the `/tmp` half only. The summary then says the Windows half was SKIPPED. For a release, such a run counts only together with a `--case isolation-canary` run that has `EVAL_CANARY_WINDIR` set.

A `--case` run never refuses: its summary notes the skipped half, with the cause.

After a Claude Code update, run `--trip-canary` once, then the suite.

**If WSL died mid-run** (a VM restart, `wsl --shutdown`, a crash), the wrapper's cleanup never ran and the run left no verdict. `/tmp` is wiped with the VM, which takes the `/tmp` sentinel and the harness's `/tmp/claude-eval-*` run directories with it. Two things survive:
- `~/logseq-eval-run.*` in the `logseq-eval` home: the exported plugin copy and the harness's output. Nothing was copied to `evals/results/`.
- `logseq-eval-canary.*` under the Windows `%TEMP%` (or `EVAL_CANARY_WINDIR`). Before removing it, list it: only `edit-target.txt`, still containing `ORIGINAL`, means nothing changed it.

When no other invocation is running, remove both as `logseq-eval`, then rerun what the dead run covered:

```
wsl -d FedoraLinux-44 -u logseq-eval -e sh -c 'rm -rf ~/logseq-eval-run.* /mnt/c/Users/<you>/AppData/Local/Temp/logseq-eval-canary.*'
```

## Cases

| Case | Checks |
|---|---|
| `isolation-canary` | Bash, Write and Edit are each attempted, and none changes the sentinels. `LOGSEQ_BRAIN_PATH` is unset inside the run |
| `load-digest` | brain-load fires. One `brain load` (or `brain digest`), no `--apply`. The page is not read with Read or through the shell. The reply says what was not read. The `(digest)` activity line is written. Tool calls ≤ 4, gating |
| `load-no-digest` | Coverage is stated. The skill offers to build a digest (its "Build one?", or an invitation such as "say the word") but does not build one: the page still has no `## Digest` and was neither edited nor rewritten. `Projects/Legacy` is 5.9 KB, so the fallback reads about 4.8 KB and the skill's "a digest brings loads to about 2 KB" is true |
| `search-scoped` | "what do we know about export?" (33 hits) gets a `brain search` whose output is counts only. No whole-page Read, no `cat`. Coverage is stated |
| `save-basic` | A Session Log entry. The save's own `brain check` prints a line for Index and for the journal, and no `brain check` line reports a new error on any file, digest findings included. The `saved` activity line. The backticked `uploadCsv()` reaches the `## Sessions` bullet intact, and no shell ever ran it. Tool calls ≤ 13, gating |
| `graph-flag-trailing` | The user config points at a decoy graph and the prompt names `./graph`. The helper reports `graph-source: flag`, the `(digest)` activity line is written, no activity bullet carries `--graph`, and the decoy gains no journal |
| `save-phantom-syntax` | With a bare `#12`, `C#-parity` and PR `#44` in the session, the Session Log gets the `44`. The save's own `brain check` prints a line for Index and for the journal, and no `brain check` line ever reports a new error on any file, digest findings included, not even one that is later fixed |
| `status-dashboard` | brain-status fires and brain-load does not. Exactly one `brain status` call. The counts line |
| `doctor-report-only` | The planted bare `#44` is reported. No Write or Edit call, no Bash call with `--apply`, and `PR #44` is still in `Notes.md` afterwards, so a scripted repair fails too |
| `init-project` | `Projects/Scratch` is created. `brain digest … --apply` runs, and the `- Map:` line ends in a measured `page | …` clause, never `pending` |
| `no-trigger` | An unrelated question fires no `brain-` skill |

## Adding a case

1. **`evals/<name>/prompt.md`.**
   - Frontmatter: `runs: 1`, `max_turns` (40 for saves and init, 25 otherwise), `timeout_seconds` (600 for saves and init, 300 otherwise), `allowed_tools: [Read, Glob, Grep, Skill]`. Quote a `description` that contains `#` or `: ` in single quotes.
   - Name the graph inline ("The graph is the folder ./graph …").
   - Pre-answer the questions this case's skill would ask, in the direction the case asserts. There is no global "assume yes".
   - Avoid words the skill reads as signals you do not intend, such as "merged" for brain-save.
2. **The graph.** Add `case.yaml` with `context.scaffold_script: scaffold.sh`, and a `scaffold.sh` that runs `sh "$(dirname "$0")/../fixtures/materialize.sh" graph [overlay-dir]`. A scaffold does **not** receive `EVAL_*` variables; the agent's Bash does.
3. **`graders/*.md`, deterministic only.**
   - Write `pattern` and `input_match` as single-quoted YAML scalars; `tools/eval/lint_cases.py` reports any other form.
   - `tool_used` inputs are matched JSON-encoded, so a quote in a command is `\"`. Match helper calls with this pattern rather than literal quotes: `(?:bin/brain|--graph\W+[^\s"\\]+)\W+(?:--graph\W+[^\s"\\]+\W+)?<command>\b`. Since v0.12.0 the helper accepts `--graph` anywhere, so a pattern must not reject a trailing `--graph` (before v0.12.0 such a call exited 2, and graders carried a tail that rejected it).
   - A must-not-fire `tool_used: Skill` grader (`min: 0`, `max: 0`) also sets `arm: both`. Otherwise a two-arm run reports it as an unscored indicator.
   - Grade "no new errors" with `match: not_contains` over the trace's check lines, including their ` · digest: <E> error` suffix, as `save-basic/graders/never-new-error.md` does. A `contains` pattern for a clean line passes as soon as any clean line exists.
   - A `trace` target also contains the prompt and every file the agent read. A `not_contains` pattern must occur in neither: `skills/_shared/hygiene-rules.md` quotes an example `check pages/Projects___X.md` line.
   - Never anchor a `trace` or `last_message` pattern to a line start: sandboxed Bash output begins with `.bashrc: Permission denied` noise. A `tool_used` input is one JSON string, so `^` is safe there.
   - Journal file names are today's date, so assert the helper's `activity:` output in the trace instead.
4. **Fixture dates** are 10-byte tokens: `@TODAY-NN@` (NN days ago) in content, `@TODAY_NN@` in file names. After changing `evals/fixtures/base-graph/`:
   - materialize a copy (`sh evals/fixtures/materialize.sh /tmp/g`);
   - regenerate any Map line there with `sh skills/_shared/bin/brain --graph /tmp/g digest <page> --apply`;
   - copy the new line back into the tokenized page;
   - update the golden cases, and run `sh tests/run.sh 'eval-fixture-*'`.
5. **Commit,** then run `sh tools/eval/test.sh`, then `run.sh --check`, then `run.sh --case <name>`.
