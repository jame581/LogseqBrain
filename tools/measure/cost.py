#!/usr/bin/env python3
"""Tool calls and bytes per logseq-brain skill invocation, from Claude Code transcripts. Dev-only; read-only.

A window starts at a Skill tool_use whose skill name contains "brain-" and ends at the next human prompt
or the next brain Skill call. Tool-result bytes are bucketed by what the matching tool_use touched:
graph (its input mentions --graph-marker), instructions (a logseq-brain skills path, or the injected
"Base directory for this skill" text), other. System reminders and task notifications do not end a window.

Usage: python tools/measure/cost.py [--since yyyy-mm-dd] [--projects ~/.claude/projects] [--graph-marker ClaudeBrain] [--csv]
"""
import argparse, collections, glob, json, os, statistics


def text_of(c):
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        return ''.join(x.get('text', '') if isinstance(x, dict) else str(x) for x in c)
    return ''


def is_human(content):
    if isinstance(content, list):
        if any(isinstance(c, dict) and c.get('type') == 'tool_result' for c in content):
            return False
        content = text_of(content)
    s = (content or '').lstrip()
    return bool(s) and not s.startswith(('<system-reminder>', '<task-notification>', 'Base directory for this skill'))


def windows(path, marker):
    uses, cur = {}, None
    for line in open(path, encoding='utf-8', errors='replace'):
        try:
            m = json.loads(line)
        except ValueError:
            continue
        msg = m.get('message') or {}
        role, content = msg.get('role'), msg.get('content')
        if role == 'user':
            if cur is not None and text_of(content).lstrip().startswith('Base directory for this skill'):
                cur['bytes']['instructions'] += len(text_of(content).encode('utf-8'))
                continue
            if is_human(content):
                if cur:
                    yield cur
                cur = None
                continue
            for c in content if isinstance(content, list) else []:
                if cur is not None and isinstance(c, dict) and c.get('type') == 'tool_result':
                    b = uses.get(c.get('tool_use_id'))
                    if b:
                        cur['bytes'][b] += len(text_of(c.get('content')).encode('utf-8'))
        elif role == 'assistant':
            if cur is not None:
                cur['out'] += (msg.get('usage') or {}).get('output_tokens', 0)
            for c in content if isinstance(content, list) else []:
                if not isinstance(c, dict) or c.get('type') != 'tool_use':
                    continue
                name, inp = c.get('name'), c.get('input') or {}
                if name == 'Skill' and 'brain-' in str(inp.get('skill', '')):
                    if cur:
                        yield cur
                    cur = {'file': os.path.basename(path), 'ts': m.get('timestamp', ''),
                           'skill': str(inp['skill']).split(':')[-1], 'calls': 0, 'out': 0,
                           'bytes': collections.Counter()}
                if cur is not None:
                    cur['calls'] += 1
                    s = json.dumps(inp, ensure_ascii=False)
                    uses[c.get('id')] = ('graph' if marker.lower() in s.lower() else
                                         'instructions' if ('logseq-brain' in s and 'skills' in s) else 'other')
    if cur:
        yield cur


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--since', default='')
    ap.add_argument('--projects', default=os.path.expanduser('~/.claude/projects'))
    ap.add_argument('--graph-marker', default='ClaudeBrain')
    ap.add_argument('--csv', action='store_true')
    a = ap.parse_args()
    ws = [w for f in glob.glob(os.path.join(a.projects, '*', '*.jsonl'))
          for w in windows(f, a.graph_marker) if w['ts'][:10] >= a.since]
    if a.csv:
        print('ts,skill,calls,graph_bytes,instruction_bytes,other_bytes,output_tokens,file')
        for w in sorted(ws, key=lambda w: w['ts']):
            b = w['bytes']
            print(f"{w['ts']},{w['skill']},{w['calls']},{b['graph']},{b['instructions']},{b['other']},{w['out']},{w['file']}")
        return
    by = collections.defaultdict(list)
    for w in ws:
        by[w['skill']].append(w)
    for skill, lst in sorted(by.items()):
        med = lambda f: statistics.median(f(w) for w in lst)
        print(f"{skill}: n={len(lst)} · calls median {med(lambda w: w['calls']):.0f} (max {max(w['calls'] for w in lst)})"
              f" · graph {med(lambda w: w['bytes']['graph']) / 1024:.1f} KB · instructions "
              f"{med(lambda w: w['bytes']['instructions']) / 1024:.1f} KB · output {med(lambda w: w['out']):.0f} tok")


if __name__ == '__main__':
    main()
