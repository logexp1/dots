#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

# The oh-my-claudecode plugin is not used, only its statusline HUD. Install the
# HUD on its own under ~/.local/share/omc-hud/<version>, where
# claude/.claude/hud/omc-hud.mjs (stowed to ~/.claude/hud) looks first.
# settings.json stays per machine / per CCS instance and points at it with:
#   "statusLine": {"type": "command", "command": "node $HOME/.claude/hud/omc-hud.mjs"}
OMC_HUD_VERSION="${OMC_HUD_VERSION:-5.7.5}"
OMC_HUD_BASE="$HOME/.local/share/omc-hud"

run() {
    log_step "claude" "Installing the standalone OMC HUD $OMC_HUD_VERSION..."
    require_cmd npm

    local dest="$OMC_HUD_BASE/$OMC_HUD_VERSION"
    if [[ -f "$dest/dist/hud/index.js" && -d "$dest/node_modules" ]]; then
        log_step "claude" "Already installed at $dest. Skipping."
        return 0
    fi

    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' RETURN
    (cd "$tmp" && npm pack "oh-my-claude-sisyphus@$OMC_HUD_VERSION" --silent >/dev/null)
    tar xzf "$tmp"/oh-my-claude-sisyphus-*.tgz -C "$tmp"

    # Runtime deps only, and skip the package's postinstall (plugin setup).
    # devDependencies are dropped from package.json first: npm still walks their
    # peer sets with --omit=dev and crashes on them (npm 10: "reading 'edgesOut'").
    node -e '
        const f = process.argv[1], p = JSON.parse(require("fs").readFileSync(f));
        delete p.devDependencies;
        require("fs").writeFileSync(f, JSON.stringify(p, null, 2));
    ' "$tmp/package/package.json"
    if ! (cd "$tmp/package" && npm install --omit=dev --ignore-scripts --no-audit --no-fund --loglevel=error); then
        log_error "claude" "npm install failed; nothing changed in $OMC_HUD_BASE"
        return 1
    fi

    rm -rf "$dest"
    mkdir -p "$OMC_HUD_BASE"
    mv "$tmp/package" "$dest"

    log_step "claude" "Installed $dest"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
