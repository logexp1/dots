# Personal Zsh cofiguration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.
if [[ -f "$HOME/.zprofile" ]]; then
	source "$HOME/.zprofile"
fi

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'no'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'pc'

# Start tmux if not already in tmux — but inside kitty use kitty sessions, not
# tmux. z4h's start-tmux default is 'integrated', so we must set 'no' explicitly
# in the kitty case; merely not setting a command leaves it on the default.
if [[ -n "$KITTY_WINDOW_ID" ]]; then
    zstyle ':z4h:' start-tmux no
else
    zstyle ':z4h:' start-tmux command tmux -u new -A -D -t z4h
fi

# Whether to move prompt to the bottom when zsh starts and on Ctrl+L.
zstyle ':z4h:' prompt-at-bottom 'no'

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'no'

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'yes'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
zstyle ':z4h:ssh:example-hostname1'   enable 'yes'
zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'no'

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh'

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`. This is just an
# example. If you don't plan to use Oh My Zsh, delete this line.
z4h install ohmyzsh/ohmyzsh || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Extend PATH.
path=(~/bin $path)

# Export environment variables.
export GPG_TTY=$TTY

# Source additional local files if they exist.
z4h source ~/.env.zsh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

# Define key bindings.
z4h bindkey z4h-backward-kill-word  Ctrl+Backspace     Ctrl+H
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace

z4h bindkey undo Ctrl+/ Shift+Tab  # undo the last command line change
z4h bindkey redo Alt+/             # redo the last undone command line change

z4h bindkey z4h-cd-back    Alt+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Alt+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Alt+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Alt+Down   # cd into a child directory

# Autoload functions.
autoload -Uz zmv

# Define functions and completions.
function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

# kitty's TERM (xterm-kitty) usually isn't installed on remote hosts, which
# breaks the zsh line editor (doubled input) and prompt over ssh. Downgrade to a
# universally-available value for ssh only. No effect inside tmux (TERM already
# normalized there) or for non-kitty terminals.
function ssh() { TERM=${TERM/xterm-kitty/xterm-256color} command ssh "$@" }
compdef _ssh ssh 2>/dev/null

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

# Define aliases.
alias tree='tree -a -I .git'

# Add flags to existing aliases.
# alias ls="${aliases[ls]:-ls} -A"
alias ls="eza -a"
alias ll="eza -al --color=always --icons --group-directories-first"
alias llt="ll --sort=newest"

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu

## * My configuration
source ~/.zsh/stow_functions.sh
# load systemd om-my-zsh plugin
emulate zsh -c 'z4h load ohmyzsh/ohmyzsh/plugins/systemd'
## Aliases
local dnfprog="dnf"

# Prefer dnf5 if installed
command -v dnf5 > /dev/null && dnfprog=dnf5

alias dnfl="${dnfprog} list"                       # List packages
alias dnfli="${dnfprog} list --installed"            # List installed packages
alias dnfgl="${dnfprog} grouplist"                 # List package groups
alias dnfmc="${dnfprog} makecache"                 # Generate metadata cache
alias dnfp="${dnfprog} info"                       # Show package information
alias dnfs="${dnfprog} search"                     # Search package

alias dnfu="sudo ${dnfprog} upgrade"               # Upgrade package
alias dnfi="sudo ${dnfprog} install"               # Install package
alias dnfgi="sudo ${dnfprog} groupinstall"         # Install package group
alias dnfr="sudo ${dnfprog} remove"                # Remove package
alias dnfgr="sudo ${dnfprog} groupremove"          # Remove package group
alias dnfc="sudo ${dnfprog} clean all"             # Clean cache

alias rldfonts='fc-cache -vf'
alias home='cd ~/'
alias cdot='cd ~/dotfiles'
alias df='ncdu'
alias rgs='rg --no-ignore --hidden --follow'
alias ports='sudo lsof -i -P -n'

# concatenate images horizontally or vertically
alias hor_concat_img='montage -mode Concatenate -tile x1 -border 20 -background black -bordercolor black'
alias vert_concat_img='montage -mode Concatenate -tile 1x -border 20 -background black -bordercolor black'
alias dump_gnome='dconf dump /org/gnome/ > ~/mydots/settings/gnome-settings.ini'
alias snaps='sudo btrbk list snapshots'
alias query_class='hyprctl clients | grep -i class'
alias doom_sync='doom sync && doom doctor'
alias nsa='(pass navercorp/KR17397 && read -s pw && echo $pw) | sudo openconnect --protocol=nc nsa-pi.navercorp.com/emergency -u jisoo.h.lee --useragent="Mozila" --no-dtls'
alias mons='hyprctl monitors all'
alias windows='hyprctl clients'
alias od_status='systemctl status --user onedrive'
alias pipi="pip install --user"

alias kernelspecs="jupyter kernelspec list"
alias brave="brave-browser --enable-wayland-ime --wayland-text-input-version=3"
alias k="k9s"
alias soundfix="systemctl --user restart wireplumber"

# alias c3d='docker run -d -t --network host --name jisoo-container -v /home1/irteam/jisoo/workspace:/home1/irteam/workspace -v /home1/irteam/jisoo/c3/bashrc:/home1/irteam/.bashrc jisoo-c3'
# alias c3i='docker exec -it jisoo-container bash'
# alias c3d='docker run -d -t \
    #     --network host  \
    # 	--name c3-container \
    #     -v /home/jisoo/c3:/home1/irteam/workspace  \
    #     c3-env \
    #     zsh'
# alias c3i='docker exec -it c3-container zsh'

alias c3='docker run -it --rm \
    --network host  \
	--name c3-container \
    -v /home/jisoo/c3/workspace:/home1/irteam/workspace  \
    c3-env \
    zsh'

# kubernetes
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
# source <(helm completion zsh)
# export KUBECONFIG=$HOME/.kube/naversearch-omni-aisuite-prod.conf


# functions
function venv-local() {
	venv=$(echo $(basename $VIRTUAL_ENV))
	echo $venv > .venv
}

function s3-ls() {
	aws --endpoint-url=$CLOVA_STORAGE_ENDPOINT s3 ls s3://clue-dataset/$1 | sort -k 1,2
}

function s3-download() {
	aws --endpoint-url=$CLOVA_STORAGE_ENDPOINT s3 cp s3://clue-dataset/$1 .
}

function pipu() {
	if [ -z $1 ]; then
		echo "usage: $0 {package to be updated via pip}"
	else
		pip install $1 --upgrade --user
	fi
}

function foccur() {
	# search files under current directory containing the query
	if [ -z $1 ]; then
		echo "usage: $0 {query to search} {(OPTIONAL) file extension}"
	elif [ -z $2 ]; then
		find -type f -exec grep -l "$1" {} \;
	else
		find . -name "*.$2" -exec grep -l "$1" {} \;
	fi
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/usr/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/usr/etc/profile.d/conda.sh" ]; then
        . "/usr/etc/profile.d/conda.sh"
    else
        export PATH="/usr/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
export KALEIDOSCOPE_DIR=/home/jisoo/build/Kaleidoscope
