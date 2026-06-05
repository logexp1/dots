# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed via [GNU Stow](https://www.gnu.org/software/stow/), plus modular Bash install scripts for bootstrapping a new machine.

## Common commands

```bash
# Show available install modules
./install.sh

# Run all modules in order
./install.sh all

# Run specific modules (any combination)
./install.sh packages stow
./install.sh nvim kitty

# Symlink all dotfiles into ~/
./install/stow.sh

# Remove all symlinks
./install/stow.sh --unstow   # or -D

# Run a single install module directly
./install/packages.sh
```

## Architecture

### Install system (`install/`)

- `install.sh` — entry point; sources and runs each selected module's `run()` function
- `install/common.sh` — shared helpers: `detect_os`, `log_step`, `log_warn`, `log_error`, `require_cmd`. Sourced by all modules. Sets `$OS` and `$BASEDIR`.
- `install/<module>.sh` — each module defines a `run()` function. Modules can also be run standalone since they guard with `[[ "${BASH_SOURCE[0]}" == "$0" ]]`.
- Current modules (in execution order): `packages root shell git emacs hyprpm wal stow gpg doom yazi`. The `packages` module sets the global npm prefix to `~/.local` (via `ensure_npm_prefix`, before any `npm install -g`) so npm globals install without sudo.

### Package lists (`install/packages/`)

One file per OS: `linux-debian` (apt), `linux-arch` (pacman). Each line is `<package> [<package-manager>]`. If no PM is given, the OS default is used. Supported non-default PMs: `yay`, `npm`, `pip`, `pipx`, `cargo`. Lines starting with `#` are treated as comments and skipped.

### Stow packages

Every top-level directory except `install/` is a stow package symlinked into `~/`. The `stow.sh` module auto-discovers them — adding a new directory is enough to include it. Before stowing, existing real directories (non-symlinks) that would conflict are backed up with a timestamp suffix.

### Package directories

| Directory  | Contents |
|-----------|----------|
| `browsing/` | Firefox user.js, Tridactyl, SurfingKeys configs |
| `common/`   | GPG, rofi, OneDrive, pass-git-helper |
| `emacs/`    | Doom Emacs config (Org-based `config.org`) |
| `kitty/`    | Kitty terminal config + themes |
| `nvim/`     | Neovim config (kickstart-based, lazy.nvim) |
| `remap/`    | XKB key remapping |
| `scripts/`  | User scripts in `bin/` (passmenu, screenshot, volume, etc.) |
| `terminal/` | zsh (z4h), tmux, foot terminal, zprofile, zshenv |
| `wm/`       | Hyprland WM, waybar, swaync, pyprland |

### Adding a new install module

1. Create `install/<name>.sh` with a `run()` function (source `common.sh` at the top).
2. Add `<name>` to the `MODULES` array in `install.sh`.

Deprecated/archived modules live in `install/archives/` and are not referenced by `install.sh`.

### Hyprland config (`wm/`)

`wm/.config/hypr/hyprland.conf` sources split config files from `wm/.config/hypr/configs/`: `envs.conf`, `settings.conf`, `monitors.conf`, `keybindings.conf`, `windowrules.conf`, `startups.conf`, `hyprfocus.conf`. Edit the relevant sub-file rather than the main conf.
