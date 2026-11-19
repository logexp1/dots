#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

GPU_LUA="${GPU_LUA:-$BASEDIR/wm/.config/hypr/configs/gpu.lua}"
GPU_LUA_EXAMPLE="$BASEDIR/wm/.config/hypr/configs/gpu.lua.example"

NVIDIA=0x10de
AMD=0x1002
INTEL=0x8086

# PCI vendor IDs of all DRM cards, one per line.
gpu_vendors() {
    local card
    for card in /sys/class/drm/card[0-9]*; do
        [[ "$card" == *-* ]] && continue # connectors are card1-DP-1 etc.
        cat "$card/device/vendor" 2>/dev/null
    done | sort -u
}

# Vendor of the card that owns a connected connector, i.e. the one that scans
# out. Empty if no display is connected (or the status is unreadable).
display_vendor() {
    local status card
    for status in /sys/class/drm/card*-*/status; do
        [[ "$(cat "$status" 2>/dev/null)" == connected ]] || continue
        card="${status%/status}"
        card="${card%%-*}"
        cat "$card/device/vendor" 2>/dev/null
        return 0
    done
    return 0
}

install_nvidia_driver() {
    if [[ "$OS" != "linux-fedora" ]]; then
        log_warn "gpu" "NVIDIA GPU found, but driver install is only automated on Fedora. Install it by hand."
        return 0
    fi

    if rpm -q akmod-nvidia &>/dev/null; then
        log_step "gpu" "NVIDIA driver already installed ($(rpm -q akmod-nvidia))."
    else
        if ! dnf repolist --enabled 2>/dev/null | grep -q '^rpmfusion-nonfree'; then
            log_error "gpu" "RPM Fusion nonfree is not enabled; run ./install.sh packages first."
            return 1
        fi
        log_step "gpu" "Installing the NVIDIA driver from RPM Fusion..."
        sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver
        log_warn "gpu" "akmods builds the kernel module on the next boot; the first boot can take a few minutes."
    fi

    # Hyprland needs DRM KMS from the NVIDIA driver.
    if ! sudo grubby --info=ALL | grep -q 'nvidia-drm.modeset=1'; then
        log_step "gpu" "Adding nvidia-drm.modeset=1 to the kernel command line..."
        sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"
    fi

    if command -v mokutil &>/dev/null && mokutil --sb-state 2>/dev/null | grep -q 'SecureBoot enabled'; then
        log_warn "gpu" "Secure Boot is on: the akmod module loads only after enrolling its key."
        log_warn "gpu" "  sudo mokutil --import /etc/pki/akmods/certs/public_key.der  (then reboot and enroll)"
    fi
}

# Write gpu.lua with the profile that matches this machine. An existing gpu.lua
# is the machine's own choice and is never touched.
seed_gpu_lua() {
    local has_nvidia="$1" display="$2"
    local lines=() reason

    if [[ -e "$GPU_LUA" ]]; then
        log_step "gpu" "$GPU_LUA already exists, leaving it as is."
        return 0
    fi

    if [[ "$has_nvidia" -eq 0 ]]; then
        reason="no NVIDIA GPU; nothing to set"
    elif [[ "$display" == "$NVIDIA" ]]; then
        reason="displays are wired to the NVIDIA GPU (profile B)"
        lines=(
            'hl.env("LIBVA_DRIVER_NAME", "nvidia")'
            'hl.env("NVD_BACKEND", "direct")'
            'hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")'
        )
    elif [[ "$display" == "$AMD" || "$display" == "$INTEL" ]]; then
        reason="displays are wired to the iGPU, NVIDIA is the dGPU (profile A)"
        lines=('hl.env("WLR_NO_HARDWARE_CURSORS", "1")')
        if [[ "$display" == "$AMD" ]]; then
            lines=('hl.env("LIBVA_DRIVER_NAME", "radeonsi")' "${lines[@]}")
        else
            lines=('hl.env("LIBVA_DRIVER_NAME", "iHD")' "${lines[@]}")
        fi
    else
        reason="NVIDIA GPU found but no connected display to decide by; pick a profile by hand"
    fi

    log_step "gpu" "Seeding $GPU_LUA: $reason"
    cp "$GPU_LUA_EXAMPLE" "$GPU_LUA"
    if (( ${#lines[@]} )); then
        printf '\n-- Chosen by install/gpu.sh: %s\n' "$reason" >> "$GPU_LUA"
        printf '%s\n' "${lines[@]}" >> "$GPU_LUA"
    fi
}

run() {
    log_step "gpu" "Detecting GPUs..."

    local vendors display has_nvidia=0
    vendors="$(gpu_vendors)"
    display="$(display_vendor)"
    grep -qx "$NVIDIA" <<< "$vendors" && has_nvidia=1

    log_step "gpu" "GPU vendors: $(tr '\n' ' ' <<< "$vendors")| displays on: ${display:-unknown}"

    if (( has_nvidia )); then
        install_nvidia_driver
    fi
    seed_gpu_lua "$has_nvidia" "$display"

    log_step "gpu" "Done."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
