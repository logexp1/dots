#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

EXCLUDE=(install)
TARGET="$HOME"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

discover_packages() {
    local packages=()
    for dir in "$BASEDIR"/*/; do
        [[ ! -d "$dir" ]] && continue
        local name
        name="$(basename "$dir")"
        local excluded=false
        for ex in "${EXCLUDE[@]}"; do
            [[ "$name" == "$ex" ]] && excluded=true && break
        done
        $excluded || packages+=("$name")
    done
    echo "${packages[@]}"
}

needs_backup() {
    local target="$1"
    # Nothing to back up if target doesn't exist (including broken symlinks)
    [[ -e "$target" || -L "$target" ]] || return 1
    # Skip if already a symlink pointing into our dots dir (stow owns it)
    if [[ -L "$target" ]]; then
        local resolved
        resolved="$(realpath "$target" 2>/dev/null || true)"
        [[ "$resolved" == "$BASEDIR"/* ]] && return 1
    fi
    return 0
}

backup_conflicts() {
    local packages=("$@")
    for pkg in "${packages[@]}"; do
        local pkg_dir="$BASEDIR/$pkg"
        [[ -d "$pkg_dir" ]] || continue

        find "$pkg_dir" -mindepth 1 -maxdepth 1 | while read -r entry; do
            local name
            name="$(basename "$entry")"

            if [[ "$name" == ".config" && -d "$entry" ]]; then
                find "$entry" -mindepth 1 -maxdepth 1 | while read -r subentry; do
                    local subname target_path backup
                    subname="$(basename "$subentry")"
                    target_path="$TARGET/.config/$subname"
                    if needs_backup "$target_path"; then
                        backup="$target_path.backup.$TIMESTAMP"
                        log_step "stow" "Backing up $target_path -> $backup"
                        mv "$target_path" "$backup"
                    fi
                done
            else
                local target_path backup
                target_path="$TARGET/$name"
                if needs_backup "$target_path"; then
                    backup="$target_path.backup.$TIMESTAMP"
                    log_step "stow" "Backing up $target_path -> $backup"
                    mv "$target_path" "$backup"
                fi
            fi
        done
    done
}

# hyprland.lua requires configs/monitors.lua and configs/gpu.lua, which are
# per-machine and gitignored, so a fresh clone has neither and Hyprland starts
# with a config error. Seed safe defaults; never touch existing files.
seed_machine_files() {
    local hypr_cfg="$BASEDIR/wm/.config/hypr/configs"
    [[ -d "$hypr_cfg" ]] || return 0

    if [[ ! -e "$hypr_cfg/monitors.lua" ]]; then
        log_step "stow" "Seeding $hypr_cfg/monitors.lua (auto layout; edit per machine)"
        printf '%s\n' \
            '-- Per-machine monitor layout (gitignored). Seeded by install/stow.sh.' \
            '-- List outputs with: hyprctl monitors all' \
            'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })' > "$hypr_cfg/monitors.lua"
    fi

    if [[ ! -e "$hypr_cfg/gpu.lua" && -f "$hypr_cfg/gpu.lua.example" ]]; then
        log_step "stow" "Seeding $hypr_cfg/gpu.lua from gpu.lua.example (inert; pick a profile)"
        cp "$hypr_cfg/gpu.lua.example" "$hypr_cfg/gpu.lua"
    fi
}

run() {
    seed_machine_files

    log_step "stow" "Discovering stow packages..."
    require_cmd stow

    local packages
    read -ra packages <<< "$(discover_packages)"

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "stow" "No stow packages found."
        return 0
    fi

    log_step "stow" "Packages: ${packages[*]}"

    # Pre-create dirs that must not be folded into symlinks by stow
    mkdir -p "$TARGET/.mozilla/native-messaging-hosts"

    backup_conflicts "${packages[@]}"
    stow -Rvt "$TARGET" -d "$BASEDIR" "${packages[@]}"
    log_step "stow" "Done."
}

unstow() {
    log_step "stow" "Discovering stow packages..."
    require_cmd stow

    local packages
    read -ra packages <<< "$(discover_packages)"

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "stow" "No stow packages found."
        return 0
    fi

    log_step "stow" "Packages: ${packages[*]}"

    stow -Dvt "$TARGET" -d "$BASEDIR" "${packages[@]}"
    log_step "stow" "Done."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        --unstow|-D) unstow ;;
        *)           run ;;
    esac
fi
