#!/usr/bin/env python3
"""Offline checks on the eval cases that the harness's $0 `run.sh --check` does not make.

  python3 lint_cases.py EVALS_DIR    one line per problem, then a summary line; exit 0 when clean, 1 otherwise

The harness validates case schema at $0 but not regex compilation or scaffold files, so a typo
would otherwise surface only in a paid run. Checks: every grader's `pattern` / `input_match` is a
single-quoted YAML scalar (evals/README.md requires it; a double-quoted or plain scalar is a
problem) that compiles, and every case.yaml `scaffold_script` exists.

The compile step is a best-effort check, not a guarantee. The harness matches with JavaScript's
RegExp, and Python's re is a different engine: the risk is a construct Python accepts that
JavaScript rejects or reads differently (possessive quantifiers, atomic groups, `\\A` and `\\Z`,
`(?P<name>)`, a leading `(?i)`; `\\d`, `\\w` and `\\b` are Unicode-aware in Python, ASCII-only in
JavaScript). The graders keep to the common subset ((?:), lookarounds, \\d \\s \\w \\b, classes,
bounded repeats), where the two agree on ASCII text.
"""
import glob
import os
import re
import sys


def frontmatter(path):
    lines = open(path, encoding='utf-8').read().split('\n')
    if not lines or lines[0] != '---':
        return None
    fields = {}
    for ln in lines[1:]:
        if ln == '---':
            return fields
        if ':' in ln and not ln.startswith((' ', '\t')):
            key, value = ln.split(':', 1)
            fields[key.strip()] = value.strip()
    return None


def scalar(raw):
    """The value of a single-quoted YAML scalar, or None for any other form."""
    if len(raw) >= 2 and raw[0] == raw[-1] == "'":
        return raw[1:-1].replace("''", "'")
    return None


def main(argv):
    if len(argv) != 2 or not os.path.isdir(argv[1]):
        print(__doc__.strip(), file=sys.stderr)
        return 2
    root = argv[1]
    problems = []
    cases = regexes = 0
    for case in sorted(glob.glob(os.path.join(root, '*', ''))):
        if not (os.path.isfile(os.path.join(case, 'prompt.md')) or os.path.isfile(os.path.join(case, 'case.yaml'))):
            continue
        cases += 1
        name = os.path.basename(os.path.dirname(case))
        for g in sorted(glob.glob(os.path.join(case, 'graders', '*.md'))):
            where = f"{name}/graders/{os.path.basename(g)}"
            fields = frontmatter(g)
            if fields is None:
                problems.append(f"{where}: no --- frontmatter block")
                continue
            for key in ('pattern', 'input_match'):
                if key not in fields:
                    continue
                value = scalar(fields[key])
                if value is None:
                    form = 'double-quoted' if fields[key][:1] == '"' else 'not quoted'
                    problems.append(f"{where}: {key} is {form}; use a single-quoted scalar")
                    continue
                regexes += 1
                try:
                    re.compile(value)
                except re.error as e:
                    problems.append(f"{where}: {key} does not compile: {e}")
        yaml = os.path.join(case, 'case.yaml')
        if os.path.isfile(yaml):
            for ln in open(yaml, encoding='utf-8'):
                m = re.match(r'\s*scaffold_script:\s*(\S+)\s*$', ln)
                if m and not os.path.isfile(os.path.join(case, m.group(1))):
                    problems.append(f"{name}/case.yaml: scaffold_script {m.group(1)} does not exist")
    for p in problems:
        print(p)
    print(f"{cases} cases, {regexes} regexes, {len(problems)} problems")
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
