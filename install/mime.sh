#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

run() {
    log_step "mime" "Setting xdg mime defaults..."
    require_cmd xdg-mime

    xdg-mime default org.pwmt.zathura.desktop application/pdf
    xdg-mime default imv.desktop image/png
    xdg-mime default imv.desktop image/jpeg
    xdg-mime default imv.desktop image/gif
    xdg-mime default imv.desktop image/webp
    xdg-mime default imv.desktop image/svg+xml

    log_step "mime" "Done."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
