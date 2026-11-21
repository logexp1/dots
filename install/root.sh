#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

SYSTEM_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/system"

run() {
    log_step "root" "Installing system root files..."

    while IFS= read -r -d '' src; do
        local rel="${src#$SYSTEM_DIR/}"
        local dest="/$rel"
        local dest_dir
        dest_dir="$(dirname "$dest")"

        sudo mkdir -p "$dest_dir"
        sudo cp "$src" "$dest"
        sudo chown root:root "$dest"
        # scripts (e.g. dispatcher hooks) stay executable, config files do not
        if [[ -x "$src" ]]; then
            sudo chmod 755 "$dest"
        else
            sudo chmod 644 "$dest"
        fi

        log_step "root" "Installed $dest"
    done < <(find "$SYSTEM_DIR" -type f -print0)

    # Pick up conf.d changes (e.g. the Wi-Fi MAC policy). A connected Wi-Fi
    # profile only switches MAC on its next connect.
    if systemctl is-active --quiet NetworkManager; then
        sudo nmcli general reload conf
        log_step "root" "Reloaded NetworkManager config (reconnect Wi-Fi to apply MAC changes)"
    fi

    log_step "root" "Done."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
