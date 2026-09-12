#!/usr/bin/env python3
"""Validate `brain lint` against Logseq OG's own parse cache. Dev-only; never shipped.

Logseq OG caches its parsed graph (a datascript DB, transit-JSON) in ~/.logseq/graphs/. Pages it
created with no backing file are ground truth for "what the parser turned into a page". This lists
them and diffs the live parse errors against `brain lint --all`.

Usage:  python tools/oracle/oracle.py --graph PATH [--transit FILE] [--sh PATH]
Exit 1 if brain lint misses a live parse-error page, or reports a tag Logseq never created.
"""
import argparse, collections, glob, json, os, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BRAIN = os.path.join(ROOT, 'skills', '_shared', 'bin', 'brain')


class Kw(str):
    pass


class Tag(str):
    pass


def decode(raw):
    """Minimal transit-JSON reader: cache codes (^ + base-44), maps ["^ ", k, v…], tagged values."""
    cache = []

    def idx(code):
        return ord(code) - 48 if len(code) == 1 else (ord(code[0]) - 48) * 44 + (ord(code[1]) - 48)

    def parse(s):
        if s[:2] in ('~~', '~^', '~`'):
            return s[1:]
        if s.startswith('~#'):
            return Tag(s[2:])
        if s.startswith('~:'):
            return Kw(s[2:])
        if s[:2] in ('~i', '~m', '~n'):
            try:
                return int(s[2:])
            except ValueError:
                return s
        return s

    def dstr(s, key=False):
        if len(s) > 1 and s[0] == '^' and s != '^ ':
            return cache[idx(s[1:])]
        v = parse(s)
        if len(s) > 3 and (key or s[:2] in ('~:', '~$', '~#')):
            if len(cache) >= 44 * 44:
                cache.clear()
            cache.append(v)
        return v

    def hk(k):
        return tuple(hk(x) for x in k) if isinstance(k, list) else k

    def dec(o, key=False):
        if isinstance(o, str):
            return dstr(o, key)
        if isinstance(o, list):
            if o and o[0] == '^ ':
                m = {}
                for i in range(1, len(o), 2):
                    k = dec(o[i], True)
                    m[hk(k)] = dec(o[i + 1])
                return m
            if not o:
                return []
            first = dec(o[0])
            if isinstance(first, Tag) and len(o) == 2:
                return ('#' + first, dec(o[1]))
            return [first] + [dec(x) for x in o[1:]]
        if isinstance(o, dict):
            m = {}
            for k, v in o.items():
                kk = dec(k, True)
                m[hk(kk)] = dec(v)
            return m
        return o

    return dec(raw)


def datoms_of(data):
    out = []

    def walk(x, depth=0):
        if depth > 6:
            return
        if isinstance(x, tuple) and len(x) == 2 and isinstance(x[0], str) and x[0].startswith('#'):
            if x[0] == '#datascript/Datom':
                out.append(x[1])
            else:
                walk(x[1], depth + 1)
        elif isinstance(x, dict):
            for v in x.values():
                walk(v, depth + 1)
        elif isinstance(x, list):
            if x and isinstance(x[0], list) and len(x[0]) >= 3 and isinstance(x[0][1], Kw):
                out.extend(x)
            else:
                for v in x:
                    walk(v, depth + 1)

    walk(data)
    return out


def phantoms(transit):
    ent = collections.defaultdict(lambda: collections.defaultdict(list))
    for d in datoms_of(decode(json.load(open(transit, encoding='utf-8')))):
        ent[d[0]][str(d[1])].append(d[2])
    pages = {e: a for e, a in ent.items() if 'block/name' in a}
    refd = collections.defaultdict(int)
    for a in ent.values():
        if 'block/content' in a:
            for r in a.get('block/refs', []):
                refd[r] += 1
    keys = set()
    for a in ent.values():
        for p in a.get('block/properties', []):
            if isinstance(p, dict):
                keys.update(str(k) for k in p)
    res = []
    for e, a in pages.items():
        if a.get('block/file'):
            continue
        name = (a.get('block/original-name') or a['block/name'])[0]
        if a.get('block/journal?', [False])[0]:
            kind = 'journal'
        elif name.lower() in keys:
            kind = 'property-key'
        elif refd.get(e):
            kind = 'referenced'
        else:
            kind = 'orphan'
        res.append((name, kind))
    return len(pages), res


def find_transit(graph):
    d = os.path.expanduser('~/.logseq/graphs')
    enc = 'logseq_local_' + graph.replace(':', '+3A+').replace('\\', '++').replace('/', '++') + '.transit'
    if os.path.exists(os.path.join(d, enc)):
        return os.path.join(d, enc)
    cands = glob.glob(os.path.join(d, '*' + os.path.basename(os.path.normpath(graph)) + '.transit'))
    if len(cands) == 1:
        return cands[0]
    sys.exit(f'transit cache not found for {graph} (looked for {enc}); pass --transit')


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
    ap = argparse.ArgumentParser()
    ap.add_argument('--graph', required=True)
    ap.add_argument('--transit')
    ap.add_argument('--sh')
    a = ap.parse_args()
    transit = a.transit or find_transit(a.graph)
    newest = max((os.path.getmtime(f) for f in glob.glob(os.path.join(a.graph, 'pages', '*.md'))), default=0)
    if os.path.getmtime(transit) < newest:
        print('warning: the transit cache is older than the newest page; open the graph in Logseq to re-parse first')
    npages, ph = phantoms(transit)
    kinds = collections.Counter(k for _, k in ph)
    print(f'oracle: {npages} pages known to Logseq, {npages - len(ph)} with a file · ' +
          ' · '.join(f'{k} {n}' for k, n in sorted(kinds.items())))
    out = subprocess.run([find_sh(a.sh), BRAIN, '--graph', a.graph, 'lint', '--all'],
                         capture_output=True, text=True, encoding='utf-8').stdout
    rows = [l.split('\t') for l in out.splitlines() if l.count('\t') >= 3]
    tags = {r[3].split(' ')[0][1:].lower() for r in rows if r[1] == 'bare-hash-tag'}
    rels = [r[3] for r in rows if r[1] == 'relative-link']
    near = lambda t, n: t == n or t.startswith(n) or n.startswith(t)
    live = [n for n, k in ph if k == 'referenced' and not n.lower().startswith(('tasks/', 'projects/'))
            and n not in ('Tasks', 'Projects')]
    missed = [n for n in live if not any(near(t, n.lower()) for t in tags)
              and not any(n.lower() in (r.lower(), os.path.basename(r).lower()) for r in rels)]
    known = {n.lower() for n, _ in ph}
    falsepos = sorted(t for t in tags if not any(near(t, n) for n in known))
    print(f'live parse errors: {len(live)} · caught by brain lint: {len(live) - len(missed)}')
    for n in missed:
        print(f'  MISSED: {n!r}')
    for t in falsepos:
        print(f'  NOT A LOGSEQ PAGE (false positive, or not yet re-parsed): #{t}')
    print('orphans persist until a re-index (Logseq: All graphs → Re-index)')
    sys.exit(1 if missed or falsepos else 0)


if __name__ == '__main__':
    main()
