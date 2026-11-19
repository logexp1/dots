#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

run() {
    log_step "hyprpm" "Setting up Hyprland plugins..."

    if ! command -v hyprpm &>/dev/null; then
        log_warn "hyprpm" "hyprpm not found, skipping."
        return 0
    fi

    # hyprpm reads the version from the running compositor.
    if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
        log_warn "hyprpm" "Hyprland is not running, skipping. Rerun ./install.sh hyprpm inside Hyprland."
        return 0
    fi

    hyprpm update
    hyprpm add https://github.com/hyprwm/hyprland-plugins || true
    hyprpm reload

	log_step "hyprpm" "Done."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
