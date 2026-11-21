# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed via [GNU Stow](https://www.gnu.org/software/stow/), plus modular Bash install scripts for bootstrapping a new machine.

## Common commands

```bash
# Pick modules from an interactive checklist (all checked by default)
./install.sh

# Show usage and available modules
./install.sh --help

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
- Current modules (in execution order): `packages gpu root shell git emacs wal stow gpg doom mime ivanti`. The `packages` module sets the global npm prefix to `~/.local` (via `ensure_npm_prefix`, before any `npm install -g`) so npm globals install without sudo. On Fedora it first tunes dnf mirror selection (fastestmirror, parallel downloads, drop mirrors under 50 KiB/s after 15s) and enables RPM Fusion and the Google Chrome repo (`setup_fedora_repos`). It then upgrades the whole system (`upgrade_system`) before installing anything, because installing onto a stale release image leaves mismatched libraries (a new Mesa with the release libdrm breaks Hyprland on AMD), and warns at the end if a new kernel needs a reboot. A failing package is logged and skipped, and the failures are listed at the end; it does not abort the run.
- `gpu` reads PCI vendor IDs from `/sys/class/drm`. With an NVIDIA GPU on Fedora it installs `akmod-nvidia` + CUDA + `libva-nvidia-driver` from RPM Fusion, adds `nvidia-drm.modeset=1` via grubby, and warns about MOK enrollment under Secure Boot. It writes `configs/gpu.lua` with the profile for the GPU that drives the connected display (NVIDIA → profile B, iGPU + NVIDIA → profile A, no NVIDIA → inert), and never overwrites an existing one.
- `root` copies everything under `install/system/` to the same path under `/` (mode 755 if the source is executable, else 644) and reloads NetworkManager's config. It holds a NetworkManager dispatcher hook for Pulse and `conf.d/22-wifi-mac-addr.conf`, which hides Fedora's `stable-ssid` Wi-Fi MAC default (Fedora 40+) so Wi-Fi connects with the hardware MAC the office network has registered.
- `stow` seeds the gitignored per-machine Hyprland files (`configs/monitors.{lua,conf}` with an auto layout, `configs/gpu.{lua,conf}` copied from the inert `.example` files) when they are missing. `gpu` only writes `gpu.lua`; on a Hyprland < 0.55 machine pick the profile in `gpu.conf` by hand.
- `ivanti` (Fedora only) installs pulsesecure together with the F42 `webkit2gtk4.0` + `javascriptcoregtk4.0` RPMs from `~/OneDrive/ivanti-f42/`, since newer Fedora dropped webkit2gtk-4.0. It skips with a hint if OneDrive hasn't synced yet.

### Package lists (`install/packages/`)

One file per OS: `linux-debian` (apt), `linux-arch` (pacman), `linux-fedora` (dnf). Each line is `<package> [<package-manager> [<extra>]]`. If no PM is given, the OS default is used. Supported non-default PMs: `yay`, `npm`, `pip`, `pipx`, `cargo`, `flatpak`, `dnf-copr <owner/project>`, `dnf-repo <.repo URL>`, `script <installer URL>` (pipes an upstream install script to bash unless the command already exists; used for the Claude Code native installer). On Fedora the whole Hyprland stack comes from the `lionheartp/Hyprland` COPR. Lines starting with `#` are treated as comments and skipped.

### Stow packages

Every top-level directory except `install/` is a stow package symlinked into `~/`. The `stow.sh` module auto-discovers them — adding a new directory is enough to include it. Before stowing, existing real directories (non-symlinks) that would conflict are backed up with a timestamp suffix.

### Package directories

| Directory  | Contents |
|-----------|----------|
| `browsing/` | Firefox user.js, Tridactyl, SurfingKeys configs |
| `claude/`   | Claude Code skills (clock-in/out) and `hud/statusline.py`, the statusline (reads Claude Code's stdin JSON; no oh-my-claudecode). Point `settings.json` at it with `"statusLine": {"type": "command", "command": "python3 $HOME/.claude/hud/statusline.py"}`; `settings.json` itself is per machine and not in the repo |
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

### Windows bootstrap (`install/windows/install.ps1`)

PowerShell counterpart of `install.sh` with modules `packages gpg passmenu tridactyl` (or `all`): winget IDs from `install/packages/windows`, gpg-agent cache config + secret key import (from `%OneDrive%\privkey.asc`, like `install/gpg.sh`) + password-store clone, pass-winmenu with a startup shortcut, and the Tridactyl native messenger + an LF copy of `browsing/.tridactylrc` at `%USERPROFILE%\.tridactylrc`. Run with `powershell -ExecutionPolicy Bypass -File install\windows\install.ps1 all`.

### Hyprland config (`wm/`)

The Hyprland config exists twice. Hyprland >= 0.55 reads `wm/.config/hypr/hyprland.lua` (and ignores `.conf` when it exists; 0.57 reads only Lua), which `require`s split modules from `wm/.config/hypr/configs/`: `envs.lua`, `startups.lua`, `settings.lua`, `keybindings.lua`, `windowrules.lua`, plus the per-machine, gitignored `monitors.lua` and `gpu.lua`. Machines still on Hyprland < 0.55 read `hyprland.conf`, which sources the matching `.conf` modules plus gitignored `monitors.conf` and `gpu.conf`. `stow` seeds all four per-machine files (auto layout, and copies of the inert `gpu.lua.example` / `gpu.conf.example`). Edit the relevant sub-file rather than the main file, **make every change in both the `.lua` and `.conf` module**, and check with `Hyprland --verify-config` (Lua) and `Hyprland --verify-config -c ~/.config/hypr/hyprland.conf` (hyprlang).

With a Lua config `hyprctl dispatch` takes Lua (`'hl.dsp.window.close()'`), and on 0.57 `hyprctl keyword` is gone. Scripts call `~/bin/hypr-dispatch '<lua>' '<legacy>'` (or `~/bin/hypr-dpms on|off`), which falls back to the legacy syntax on a hyprlang config. Tools that talk to Hyprland's IPC need Lua-aware versions (pyprland >= 3.4, hyprland-autoname-workspaces from git).
