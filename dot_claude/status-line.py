#!/usr/bin/env python3
"""Pattern 5: Braille dots - dotted progress bar using braille characters"""
import json, sys, os, subprocess
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

data = json.load(sys.stdin)

BRAILLE = ' ⣀⣄⣤⣦⣶⣷⣿'
R = '\033[0m'
DIM = '\033[2m'
BOLD = '\033[1m'
CYAN = '\033[36m'

def gradient(pct):
    if pct < 50:
        r = int(pct * 5.1)
        return f'\033[38;2;{r};200;80m'
    else:
        g = int(200 - (pct - 50) * 4)
        return f'\033[38;2;255;{max(g, 0)};60m'

def braille_bar(pct, width=8):
    pct = min(max(pct, 0), 100)
    level = pct / 100
    bar = ''
    for i in range(width):
        seg_start = i / width
        seg_end = (i + 1) / width
        if level >= seg_end:
            bar += BRAILLE[7]
        elif level <= seg_start:
            bar += BRAILLE[0]
        else:
            frac = (level - seg_start) / (seg_end - seg_start)
            bar += BRAILLE[min(int(frac * 7), 7)]
    return bar

def fmt(label, pct):
    p = round(pct)
    return f'{DIM}{label}{R} {gradient(pct)}{braille_bar(pct)}{R} {p}%'

cwd = (data.get('workspace', {}) or {}).get('current_dir') or data.get('cwd') or os.getcwd()

repo_name = ''
branch = ''
try:
    toplevel = subprocess.check_output(
        ['git', 'rev-parse', '--show-toplevel'],
        cwd=cwd, stderr=subprocess.DEVNULL, timeout=0.5
    ).decode().strip()
    repo_name = os.path.basename(toplevel)
except Exception:
    pass

try:
    branch = subprocess.check_output(
        ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        cwd=cwd, stderr=subprocess.DEVNULL, timeout=0.5
    ).decode().strip()
except Exception:
    pass

project_name = repo_name or os.path.basename(cwd) or 'claude'

model = data.get('model', {}).get('display_name', 'Claude')
project_label = f'{BOLD}{CYAN}{project_name}{R}'
if branch:
    project_label += f' {DIM}[{branch}]{R}'
top = [project_label, f'{DIM}{model}{R}']

bottom = []
ctx = data.get('context_window', {}).get('used_percentage')
if ctx is not None:
    bottom.append(fmt('ctx', ctx))

five = data.get('rate_limits', {}).get('five_hour', {}).get('used_percentage')
if five is not None:
    bottom.append(fmt('5h', five))

week = data.get('rate_limits', {}).get('seven_day', {}).get('used_percentage')
if week is not None:
    bottom.append(fmt('7d', week))

sep = f' {DIM}│{R} '
lines = [sep.join(top)]
if bottom:
    lines.append(sep.join(bottom))
print('\n'.join(lines), end='')
