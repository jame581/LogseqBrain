#!/usr/bin/env python3
"""Map accuracy at write time, and new error-tier findings per edit interval, from Logseq's own page
snapshots (logseq/bak/, logseq/version-files/local/) plus the current files. Dev-only.

Every probe runs the real helper against a temporary copy of the graph; the graph itself is never
modified. Map accuracy: `brain digest` on the first snapshot carrying each distinct ## Digest text.
New findings: `brain sections --baseline` on the older version, then `brain check` on the newer one.

Usage: python tools/measure/snapshots.py --graph PATH [--since yyyy-mm-dd] [--sh PATH]
"""
import argparse, collections, datetime, glob, hashlib, os, re, shutil, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BRAIN = os.path.join(ROOT, 'skills', '_shared', 'bin', 'brain')
TS = re.compile(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2})_(\d{2})_(\d{2})')
DIGEST = re.compile(r'(?ms)^\s*(?:- )?## Digest\s*$.*?(?=^\s*(?:- )?## |\Z)')


def timelines(graph):
    v = collections.defaultdict(list)
    for root in ('bak', os.path.join('version-files', 'local')):
        for f in glob.glob(os.path.join(graph, 'logseq', root, '*', '*', '*.md')):
            m = TS.match(os.path.basename(f))
            if m:
                kind = os.path.basename(os.path.dirname(os.path.dirname(f)))
                key = f'{kind}/{os.path.basename(os.path.dirname(f))}.md'
                v[key].append((datetime.datetime(*map(int, m.groups())), open(f, 'rb').read()))
    for key in list(v):
        cur = os.path.join(graph, key)
        if os.path.exists(cur):
            v[key].append((datetime.datetime.fromtimestamp(os.path.getmtime(cur), datetime.timezone.utc).replace(tzinfo=None),
                           open(cur, 'rb').read()))
    for key, vs in v.items():
        vs.sort(key=lambda x: x[0])
        seen, uniq = set(), []
        for t, b in vs:
            h = hashlib.md5(b).hexdigest()
            if h not in seen:
                seen.add(h)
                uniq.append((t, b))
        v[key] = uniq
    return v


def find_sh(explicit):
    if explicit:
        return explicit
    sh = shutil.which('sh')
    if sh:
        return sh
    git = shutil.which('git')
    if git:
        cand = os.path.join(os.path.dirname(os.path.dirname(git)), 'bin', 'bash.exe')
        if os.path.exists(cand):
            return cand
    sys.exit('no sh found; pass --sh (Git for Windows: C:\\Program Files\\Git\\bin\\bash.exe)')


def main():
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass
    ap = argparse.ArgumentParser()
    ap.add_argument('--graph', required=True)
    ap.add_argument('--since', default='')
    ap.add_argument('--sh')
    a = ap.parse_args()
    sh = find_sh(a.sh)
    tmp = tempfile.mkdtemp(prefix='brain-snap-')
    try:
        for d in ('pages', 'journals'):
            shutil.copytree(os.path.join(a.graph, d), os.path.join(tmp, d))
        fails = collections.Counter()

        def brain(*args):
            p = subprocess.run([sh, BRAIN, '--graph', tmp, *args], capture_output=True,
                               text=True, encoding='utf-8', errors='replace')
            if p.returncode not in (0, 1):
                fails['n'] += 1
            return p.stdout
        maps = collections.Counter(); bad = []; errs = collections.Counter(); intervals = 0
        for key, vs in timelines(a.graph).items():
            target = os.path.join(tmp, key)
            first_digest = set()
            for i, (t, body) in enumerate(vs):
                if t.isoformat()[:10] < a.since:
                    continue
                text = body.decode('utf-8', 'replace')
                m = DIGEST.search(text)
                if key.startswith('pages/') and m and m.group(0) not in first_digest:
                    first_digest.add(m.group(0))
                    open(target, 'wb').write(body)
                    line = next((l for l in brain('digest', key).splitlines() if l.startswith('map:')), 'map: ?')
                    maps[line.split(' ')[1]] += 1
                    if not line.startswith('map: ok'):
                        bad.append(f'{key} @ {t:%Y-%m-%d %H:%M}: {line}')
                if i > 0:
                    open(target, 'wb').write(vs[i - 1][1])
                    brain('sections', key)
                    open(target, 'wb').write(body)
                    out = brain('check', key)
                    intervals += 1
                    for l in out.splitlines():
                        if '\terror\t' in l and '(no baseline' not in l:
                            errs[l.split('\t')[1]] += 1
        print('Map at first appearance: ' + ', '.join(f'{k} {n}' for k, n in sorted(maps.items())))
        for b in bad:
            print('  ' + b)
        print(f'intervals checked: {intervals} · new error-tier findings: ' +
              (', '.join(f'{k} {n}' for k, n in errs.most_common()) or 'none'))
        if fails['n']:
            print(f'helper failures: {fails["n"]}')
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    main()
