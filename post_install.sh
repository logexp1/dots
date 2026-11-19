#!/bin/bash
# Steps that need a running Hyprland session. Run once after ./install.sh,
# rebooting and logging in to Hyprland.
set -e

if [[ $EUID -eq 0 ]]; then
    echo "Please run this script as a regular user, not root."
    exit 1
fi

INSTALL_DIR="$(dirname "$(realpath "$0")")/install"
source "$INSTALL_DIR/common.sh"

POST_MODULES=(hyprpm)

if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    log_error "post_install" "Hyprland is not running. Log in to Hyprland and run this from a terminal there."
    exit 1
fi

for mod in "${POST_MODULES[@]}"; do
    echo ""
    source "$INSTALL_DIR/${mod}.sh"
    run
done

echo ""
log_step "post_install" "All done!"
