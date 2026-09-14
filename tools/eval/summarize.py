#!/usr/bin/env python3
"""Summarize a `claude plugin eval --json` result for tools/eval/run.sh.

  python3 summarize.py table RESULT_JSON    per-run table, failed graders, totals;
                                            exit 0 when every case passed, 1 otherwise
  python3 summarize.py traces RESULT_JSON   one "<case>\t<run>\t<tracePath>" line per kept trace
  python3 summarize.py passed RESULT_JSON CASE
                                            exit 0 when CASE ran and scored at least the threshold

Tool calls per run = the tool_use blocks in that run's trace.jsonl from the first brain- Skill call
onward, that call included: the window tools/measure/cost.py uses, so the figures compare with real
use. A run in which no brain- skill fired counts every call. Figures are reported, never gating: an
over-target count is flagged OVER but does not change the exit code (spec 2026-09-13-eval-suite-design.md §7).
A relative tracePath resolves against the result file's directory.
"""
import json
import os
import sys

TARGETS = {'load-digest': 4, 'save-basic': 13}


def trace_path(result_file, run):
    p = run.get('tracePath')
    if not p:
        return None
    return p if os.path.isabs(p) else os.path.join(os.path.dirname(os.path.abspath(result_file)), p)


def tool_calls(path):
    if not path or not os.path.isfile(path):
        return None
    total = 0
    since_skill = None  # None until a brain- Skill call is seen
    with open(path, encoding='utf-8', errors='replace') as f:
        for line in f:
            try:
                o = json.loads(line)
            except ValueError:
                continue
            msg = o.get('message') if isinstance(o, dict) else None
            content = msg.get('content') if isinstance(msg, dict) else None
            for c in content if isinstance(content, list) else []:
                if not isinstance(c, dict) or c.get('type') != 'tool_use':
                    continue
                total += 1
                inp = c.get('input') if isinstance(c.get('input'), dict) else {}
                if since_skill is None and c.get('name') == 'Skill' and 'brain-' in str(inp.get('skill', '')):
                    since_skill = 0
                if since_skill is not None:
                    since_skill += 1
    return total if since_skill is None else since_skill


def runs(d):
    for c in d.get('cases', []):
        for i, r in enumerate(c.get('arms', {}).get('with', []), 1):
            yield c, i, r


def table(result_file):
    with open(result_file, encoding='utf-8') as f:
        d = json.load(f)
    threshold = d.get('suite', {}).get('threshold', 1)
    print(f"{'case':<22} {'run':>3} {'result':<6} {'score':>5} {'tools':>5} {'target':<9} {'cost':>7} {'time':>5}")
    failures = []
    for c, i, r in runs(d):
        name = c.get('name', '?')
        n = tool_calls(trace_path(result_file, r))
        target = '-'
        if name in TARGETS and n is not None:
            target = f"<={TARGETS[name]} " + ('ok' if n <= TARGETS[name] else 'OVER')
        result = 'pass' if r.get('passed') else 'FAIL'
        print(f"{name:<22} {i:>3} {result:<6} {r.get('score', 0):>5.2f} {'-' if n is None else n:>5} "
              f"{target:<9} {'$%.2f' % (r.get('costUsd') or 0):>7} {'%ds' % (r.get('durationSeconds') or 0):>5}")
        if r.get('error'):
            failures.append(f"  {name} #{i}: run error: {r['error']}")
        for g in r.get('graders', []):
            if g.get('scored', True) and not g.get('passed'):
                failures.append(f"  {name} #{i} / {g.get('name')}: {g.get('explanation')}")
    cases = d.get('cases', [])
    passed = sum(1 for c in cases if c.get('aggregates', {}).get('score', 0) >= threshold)
    print(f"total: {len(cases)} cases, {passed} passed · cost ${d.get('costUsd') or 0:.2f} · "
          f"{d.get('durationSeconds') or 0}s" + (' · PARTIAL' if d.get('partial') else ''))
    if failures:
        print('failed graders and run errors:')
        print('\n'.join(failures))
    return 0 if cases and passed == len(cases) else 1


def traces(result_file):
    with open(result_file, encoding='utf-8') as f:
        d = json.load(f)
    for c, i, r in runs(d):
        p = trace_path(result_file, r)
        if p:
            print(f"{c.get('name', '?')}\t{i}\t{p}")
    return 0


def passed(result_file, name):
    with open(result_file, encoding='utf-8') as f:
        d = json.load(f)
    threshold = d.get('suite', {}).get('threshold', 1)
    ok = any(c.get('name') == name and c.get('aggregates', {}).get('score', 0) >= threshold
             for c in d.get('cases', []))
    return 0 if ok else 1


def main(argv):
    if len(argv) == 3 and argv[1] in ('table', 'traces'):
        return table(argv[2]) if argv[1] == 'table' else traces(argv[2])
    if len(argv) == 4 and argv[1] == 'passed':
        return passed(argv[2], argv[3])
    print(__doc__.strip(), file=sys.stderr)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv))
