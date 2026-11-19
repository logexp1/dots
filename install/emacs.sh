#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

run() {
    local force=0
    for arg in "$@"; do
        [[ "$arg" == "--force" ]] && force=1
    done

    if command -v emacs &>/dev/null && [[ "$force" -eq 0 ]]; then
        log_step "emacs" "Emacs already installed ($(emacs --version | head -1)). Skipping build. Use --force to rebuild."
        return 0
    fi

    log_step "emacs" "Building Emacs from source..."
    require_cmd git
    require_cmd make
    require_cmd autoconf

    local build_dir="$HOME/build"
    local emacs_src="$build_dir/emacs"
    mkdir -p "$build_dir"

	local emacs_branch="emacs-31.1"
    if [[ -d "$emacs_src" ]]; then
        log_step "emacs" "Source directory already exists, pulling latest..."
        git -C "$emacs_src" fetch
        git -C "$emacs_src" checkout $emacs_branch
        git -C "$emacs_src" pull --ff-only || true
    else
        log_step "emacs" "Cloning Emacs repository..."
        git clone git://git.savannah.gnu.org/emacs.git "$emacs_src"
        git -C "$emacs_src" checkout $emacs_branch
    fi

    log_step "emacs" "Running autogen.sh..."
    (cd "$emacs_src" && ./autogen.sh)

    log_step "emacs" "Configuring..."
    (cd "$emacs_src" && ./configure --disable-gc-mark-trace \
        --with-cairo \
        --with-dbus \
        --with-gif \
        --with-gpm=no \
        --with-harfbuzz \
        --with-jpeg \
        --with-modules \
        --with-native-compilation=aot \
        --with-pgtk \
        --with-png \
        --with-rsvg \
        --with-sqlite3 \
        --with-tiff \
        --with-tree-sitter \
        --with-webp \
        --with-xpm
	)

    log_step "emacs" "Bootstrapping..."

    local nproc
    if command -v nproc &>/dev/null; then
        nproc=$(nproc)
    elif command -v sysctl &>/dev/null; then
        nproc=$(sysctl -n hw.ncpu)
    else
        nproc=1
    fi

    make -C "$emacs_src" bootstrap -j"$nproc"

    log_step "emacs" "Installing (requires sudo)..."
    sudo make -C "$emacs_src" install

    log_step "emacs" "Done."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run "$@"
fi
