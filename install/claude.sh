#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

# Point Claude Code's statusline at claude/.claude/hud/statusline.py (stowed to
# ~/.claude/hud/). settings.json is per machine and not in the repo, so only the
# statusLine key is set and everything else in it is left alone. CCS instances
# whose settings.json is a real file (not a link to ~/.claude) get it too.
# Also clears leftovers of the oh-my-claudecode HUD this replaced.
STATUSLINE_CMD='python3 $HOME/.claude/hud/statusline.py'

set_statusline() {
    local file="$1"
    python3 - "$file" "$STATUSLINE_CMD" <<'EOF'
import json, os, sys
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)
want = {'type': 'command', 'command': cmd}
if data.get('statusLine') == want and 'omcHud' not in data:
    sys.exit(0)
data['statusLine'] = want
data.pop('omcHud', None)
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
print(f'updated {path}')
EOF
}

run() {
    log_step "claude" "Setting the Claude Code statusline..."

    set_statusline "$HOME/.claude/settings.json"
    local inst
    for inst in "$HOME"/.ccs/instances/*/settings.json; do
        [[ -f "$inst" && ! -L "$inst" ]] && set_statusline "$inst"
    done

    # oh-my-claudecode HUD leftovers
    rm -rf "$HOME/.local/share/omc-hud"
    local link="$HOME/.claude/hud/omc-hud.mjs"
    if [[ -L "$link" && ! -e "$link" ]]; then
        rm -f "$link"
    fi

    if [[ ! -e "$HOME/.claude/hud/statusline.py" ]]; then
        log_warn "claude" "~/.claude/hud/statusline.py is missing; run ./install.sh stow"
    fi
    log_step "claude" "Done. Restart Claude Code to pick it up."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
