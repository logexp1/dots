#!/usr/bin/env python3
"""Claude Code statusline.

settings.json:  "statusLine": {"type": "command", "command": "python3 $HOME/.claude/hud/statusline.py"}

Claude Code pipes a JSON blob on stdin (model, effort, context_window,
rate_limits, cost, ...) on every refresh; everything shown here comes from it,
plus the git branch and the CCS profile, so there are no network calls.

    branch:main | profile:team
    Model: Opus 5.5 | effort:medium | ctx:[###-------]34% | 5h:[--------]4%(2h4m) wk:[#-------]14%(4d18h) | thinking | session:17m

Reorder or drop elements in LINES below.
"""
import json
import os
import subprocess
import sys
import time

DIM, BOLD, CYAN, GREEN, YELLOW, RED, RESET = (
    '\033[2m', '\033[1m', '\033[36m', '\033[32m', '\033[33m', '\033[31m', '\033[0m')
SEP = f'{DIM} | {RESET}'


def pct_color(p):
    return GREEN if p < 70 else YELLOW if p < 85 else RED


def bar(p, width):
    filled = max(0, min(width, round(p * width / 100)))
    return f'[{pct_color(p)}{"#" * filled}{DIM}{"-" * (width - filled)}{RESET}]{pct_color(p)}{p:.0f}%{RESET}'


def until(epoch):
    secs = int(epoch - time.time())
    if secs <= 0:
        return ''
    d, h, m = secs // 86400, secs % 86400 // 3600, secs % 3600 // 60
    return f'{DIM}({d}d{h}h){RESET}' if d else f'{DIM}({h}h{m}m){RESET}'


# --- elements: each takes the stdin dict and returns a string, or '' to hide ---

def branch(s):
    cwd = s.get('cwd') or s.get('workspace', {}).get('current_dir') or '.'
    try:
        out = subprocess.run(['git', '-C', cwd, 'branch', '--show-current'],
                             capture_output=True, text=True, timeout=1).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ''
    return f'{DIM}branch:{RESET}{CYAN}{out}{RESET}' if out else ''


def profile(s):
    # CCS runs each profile with CLAUDE_CONFIG_DIR=~/.ccs/instances/<name>
    cfg = os.environ.get('CLAUDE_CONFIG_DIR', '').rstrip('/')
    parent, name = os.path.split(cfg)
    return f'{BOLD}profile:{name}{RESET}' if name and os.path.basename(parent) == 'instances' else ''


def model(s):
    name = s.get('model', {}).get('display_name')
    return f'{CYAN}Model: {name}{RESET}' if name else ''


def effort(s):
    level = (s.get('effort') or {}).get('level')
    return f'{CYAN}effort:{level}{RESET}' if level else ''


def context(s):
    p = (s.get('context_window') or {}).get('used_percentage')
    return f'ctx:{bar(p, 10)}' if p is not None else ''


def rate_limits(s):
    rl = s.get('rate_limits') or {}
    parts = []
    for key, label in (('five_hour', '5h'), ('seven_day', 'wk')):
        w = rl.get(key) or {}
        if w.get('used_percentage') is not None:
            parts.append(f'{DIM if parts else ""}{label}:{RESET}{bar(w["used_percentage"], 8)}'
                         f'{until(w["resets_at"]) if w.get("resets_at") else ""}')
    return ' '.join(parts)


def thinking(s):
    return f'{CYAN}thinking{RESET}' if (s.get('thinking') or {}).get('enabled') else ''


def session(s):
    ms = (s.get('cost') or {}).get('total_duration_ms')
    if ms is None:
        return ''
    m = int(ms // 60000)
    color = GREEN if m < 60 else YELLOW if m < 180 else RED
    return f'session:{color}{m}m{RESET}'


LINES = [
    [branch, profile],
    [model, effort, context, rate_limits, thinking, session],
]


def main():
    try:
        s = json.load(sys.stdin)
    except ValueError:
        s = {}
    for line in LINES:
        parts = []
        for element in line:
            try:
                text = element(s)
            except Exception:  # one broken element must not blank the statusline
                text = ''
            if text:
                parts.append(text)
        if parts:
            print(SEP.join(parts))


if __name__ == '__main__':
    main()
