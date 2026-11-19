#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

PACKAGES_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/packages"

NPM_PREFIX="$HOME/.local"

# Point npm's global prefix at ~/.local so `npm install -g` works without sudo.
# Idempotent: no-op if npm is missing or already configured. Must run before any
# `npm install -g`, hence it is invoked lazily from the npm package-manager case.
ensure_npm_prefix() {
    command -v npm &>/dev/null || return 0
    [[ "$(npm config get prefix 2>/dev/null)" == "$NPM_PREFIX" ]] && return 0
    log_step "packages" "Configuring npm global prefix -> $NPM_PREFIX"
    npm config set prefix "$NPM_PREFIX"
}

# Third-party repos that can't be expressed as a per-line dnf-copr/dnf-repo
# entry: RPM Fusion (dropbox, codecs) ships release RPMs, and Google Chrome's
# repo comes disabled in fedora-workstation-repositories. Idempotent.
setup_fedora_repos() {
    local ver
    ver="$(rpm -E %fedora)"

    # A fresh install keeps dnf's defaults, under which a stalled mirror is
    # dropped only after 30s below 1 KB/s. Pick the nearest mirror, download in
    # parallel, and abandon any mirror under 50 KiB/s for 15s. Written to
    # /etc/dnf/libdnf5.conf.d/20-user-settings.conf; re-running is a no-op.
    log_step "packages" "Tuning dnf mirror selection and timeouts..."
    sudo dnf config-manager setopt \
        fastestmirror=True max_parallel_downloads=10 minrate=51200 timeout=15 \
        || log_warn "packages" "Could not tune dnf settings; continuing with defaults."
    sudo dnf makecache --refresh \
        || log_warn "packages" "dnf makecache failed; mirrors may be unreachable."

    if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release &>/dev/null; then
        log_step "packages" "Enabling RPM Fusion (free + nonfree)..."
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${ver}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${ver}.noarch.rpm" \
            || log_warn "packages" "RPM Fusion setup failed; dropbox will fail below."
    fi

    if ! dnf repolist --enabled 2>/dev/null | grep -q '^google-chrome'; then
        log_step "packages" "Enabling the Google Chrome repo..."
        { sudo dnf install -y fedora-workstation-repositories \
            && sudo dnf config-manager setopt google-chrome.enabled=1; } \
            || log_warn "packages" "Chrome repo setup failed; google-chrome-stable will fail below."
    fi
}

# Bring the whole system up to date before installing anything. Installing on
# top of a stale release image pulls new libraries in only as dependencies,
# which can leave mismatched pairs behind (e.g. a new Mesa next to the release
# libdrm, under which Hyprland cannot initialise an AMD GPU). On Fedora this
# runs after setup_fedora_repos so RPM Fusion's packages are updated too.
upgrade_system() {
    log_step "packages" "Upgrading the system before installing packages..."
    case "$OS" in
        linux-fedora) sudo dnf upgrade -y --refresh ;;
        linux-debian) sudo apt upgrade -y ;;
        linux-arch)   sudo pacman -Syu --noconfirm ;;
        *) return 0 ;;
    esac || log_warn "packages" "System upgrade failed; packages below may pull mismatched libraries."
}

# The upgrade above may install a new kernel; driver modules (akmod-nvidia) and
# the graphics stack expect it, so say so instead of leaving it to be found.
warn_if_reboot_needed() {
    [[ "$OS" == "linux-fedora" ]] || return 0
    local newest
    newest="$(rpm -q --last kernel-core 2>/dev/null | head -1 | awk '{print $1}')"
    newest="${newest#kernel-core-}"
    if [[ -n "$newest" && "$newest" != "$(uname -r)" ]]; then
        log_warn "packages" "Kernel $newest was installed but $(uname -r) is running. Reboot before starting Hyprland."
    fi
}

default_pm() {
    case "$OS" in
        linux-debian) echo "apt" ;;
        linux-arch)   echo "pacman" ;;
        linux-fedora) echo "dnf" ;;
        macos)        echo "brew" ;;
        *)
            log_error "packages" "Cannot determine default package manager for OS: $OS"
            return 1
            ;;
    esac
}

install_with() {
    local pm="$1"
    local pkg="$2"
    local extra="${3:-}"

    case "$pm" in
        apt)
            # Explicit return: errexit is off inside `if ! install_with`, and
            # the trailing rustup `if` would otherwise mask an apt failure.
            sudo apt install -y "$pkg" || return 1
            [[ "$pkg" == "npm" ]] && ensure_npm_prefix
            if [[ "$pkg" == "rustup" ]]; then
                log_step "packages" "Initializing rustup with stable toolchain..."
                rustup default stable
                source "$HOME/.cargo/env"
            fi
            ;;
        pacman)
            sudo pacman -S --noconfirm "$pkg"
            ;;
        dnf)
            sudo dnf install -y "$pkg"
            ;;
        dnf-repo)
            local repo_id
            repo_id=$(basename "$extra" .repo)
            if ! sudo dnf repolist --enabled | grep -q "^$repo_id"; then
                sudo dnf config-manager addrepo --from-repofile="$extra" || return 1
            fi
            sudo dnf install -y --repo "$repo_id" "$pkg"
            ;;
        dnf-copr)
            if ! sudo dnf copr list --enabled 2>/dev/null | grep -q "$extra"; then
                # || return: otherwise a failed enable falls through and a
                # package that also exists in Fedora installs from the wrong repo.
                sudo dnf copr enable -y "$extra" || return 1
            fi
            sudo dnf install -y "$pkg"
            ;;
        brew)
            brew install "$pkg"
            ;;
        yay)
            yay -S --noconfirm "$pkg"
            ;;
        npm)
            ensure_npm_prefix
            npm install -g "$pkg"
            ;;
        pip)
            pip install --user "$pkg"
            ;;
		pipx)
			if ! command -v pipx &>/dev/null; then
				log_step "packages" "pipx not found, installing..."
				case "$OS" in
					linux-fedora) sudo dnf install -y pipx ;;
					linux-debian) sudo apt install -y pipx ;;
					linux-arch)   sudo pacman -S --noconfirm python-pipx ;;
				esac
			fi
			pipx install "$pkg" || pipx upgrade "$pkg"
			;;
		cargo)
			[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
			# `cargo --version`, not `command -v cargo`: a rustup proxy can be
			# on PATH with no toolchain installed, and then every install fails.
			if ! cargo --version &>/dev/null; then
				log_step "packages" "No working cargo, installing rustup + stable toolchain..."
				case "$OS" in
					linux-fedora) sudo dnf install -y rustup && rustup-init -y ;;
					linux-debian) sudo apt install -y rustup && rustup default stable ;;
					linux-arch)   sudo pacman -S --noconfirm rust ;;
				esac
				source "$HOME/.cargo/env"
			fi
			if [[ "$pkg" == git+* ]]; then
				local git_url="${pkg#git+}"
				local git_bin=""
				if [[ "$git_url" == *#* ]]; then
					git_bin="${git_url#*#}"
					git_url="${git_url%#*}"
				fi
				cargo install --git "$git_url" ${git_bin:+"$git_bin"}
			else
				cargo install "$pkg" --locked
			fi
            ;;
        flatpak)
            if ! command -v flatpak &>/dev/null; then
                log_step "packages" "flatpak not found, installing..."
                case "$OS" in
                    linux-fedora) sudo dnf install -y flatpak ;;
                    linux-debian) sudo apt install -y flatpak ;;
                    linux-arch)   sudo pacman -S --noconfirm flatpak ;;
                esac
            fi
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
            flatpak install -y flathub "$pkg"
            ;;
        *)
            log_error "packages" "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

run() {
    log_step "packages" "Installing packages for $OS..."

    if [[ "$OS" == "linux-debian" ]]; then
        log_step "packages" "Updating apt package index..."
        sudo apt update -qq
    fi

    [[ "$OS" == "linux-fedora" ]] && setup_fedora_repos
    upgrade_system

    local failed=()

    local pkg_file="$PACKAGES_DIR/$OS"
    if [[ ! -f "$pkg_file" ]]; then
        log_error "packages" "No package list found at $pkg_file"
        return 1
    fi

    local default
    default="$(default_pm)"

    while IFS= read -r line || [[ -n "$line" ]]; do
        # skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        local pkg pm extra
        pkg="$(echo "$line" | awk '{print $1}')"
        pm="$(echo "$line" | awk '{print $2}')"
        pm="${pm:-$default}"
        extra="$(echo "$line" | awk '{print $3}')"

        log_step "packages" "Installing $pkg with $pm..."
        # One bad line must not abort the remaining packages: record it and
        # move on. stdin is detached so an installer that reads it cannot
        # swallow the rest of the package list.
        if ! install_with "$pm" "$pkg" "$extra" </dev/null; then
            log_error "packages" "Failed: $pkg ($pm)"
            failed+=("$pkg ($pm)")
        fi
    done < "$pkg_file"

    ensure_npm_prefix
    warn_if_reboot_needed

    # Report but don't fail the module: later modules (stow especially) are
    # still worth running, and the list tells you what to retry.
    if (( ${#failed[@]} )); then
        log_error "packages" "${#failed[@]} package(s) failed; retry them by hand:"
        printf '  %s\n' "${failed[@]}" >&2
    fi

    log_step "packages" "Done."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
