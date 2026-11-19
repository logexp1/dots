#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

# Ivanti Secure Access (pulsesecure) needs webkit2gtk-4.0, which Fedora dropped
# after F42. The F42 webkit2gtk4.0 + javascriptcoregtk4.0 RPMs still install on
# newer Fedora (their system deps resolve on F43/F44), so they are kept in
# OneDrive with the Ivanti installer. Run after OneDrive has synced.
IVANTI_DIR="${IVANTI_DIR:-$HOME/OneDrive}"
WEBKIT_DIR="${WEBKIT_DIR:-$IVANTI_DIR/ivanti-f42}"

run() {
    log_step "ivanti" "Installing Ivanti VPN client..."

    if [[ "$OS" != "linux-fedora" ]]; then
        log_warn "ivanti" "Only supported on Fedora (OS=$OS), skipping."
        return 0
    fi

    if rpm -q pulsesecure &>/dev/null; then
        log_step "ivanti" "pulsesecure already installed ($(rpm -q pulsesecure)). Skipping."
        return 0
    fi

    local webkit_rpms=() installer
    shopt -s nullglob
    # [0-9]* so -devel/-debuginfo subpackages next to them don't match
    webkit_rpms=("$WEBKIT_DIR"/webkit2gtk4.0-[0-9]*.rpm "$WEBKIT_DIR"/javascriptcoregtk4.0-[0-9]*.rpm)
    shopt -u nullglob
    installer="$(find "$IVANTI_DIR" -maxdepth 1 -name 'ps-pulse-linux-*-installer.rpm' 2>/dev/null | sort -V | tail -1)"

    if (( ${#webkit_rpms[@]} != 2 )) || [[ -z "$installer" ]]; then
        log_warn "ivanti" "RPMs not found. Expected webkit2gtk4.0 + javascriptcoregtk4.0 in $WEBKIT_DIR"
        log_warn "ivanti" "and ps-pulse-linux-*-installer.rpm in $IVANTI_DIR."
        log_warn "ivanti" "Sync OneDrive first (run 'onedrive' once to log in), then: ./install.sh ivanti"
        return 0
    fi

    # One transaction so dnf resolves the installer's webkit dependency
    # against the local F42 RPMs instead of looking for it in the repos.
    log_step "ivanti" "Installing ${webkit_rpms[*]##*/} $(basename "$installer")"
    sudo dnf install -y "${webkit_rpms[@]}" "$installer"

    local lib
    for lib in /usr/lib64/libwebkit2gtk-4.0.so.*; do
        [[ -e "$lib" && ! -L "$lib" ]] || continue
        if ldd "$lib" | grep -q 'not found'; then
            log_warn "ivanti" "$lib has unresolved libraries:"
            ldd "$lib" | grep 'not found' >&2
        fi
    done

    log_step "ivanti" "Done. Check libwebkit2gtk-4.0 with ldd before every Fedora upgrade."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
