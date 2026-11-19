#!/bin/bash
set -e

if [[ $EUID -eq 0 ]]; then
    echo "Please run this script as a regular user, not root."
    exit 1
fi

INSTALL_DIR="$(dirname "$(realpath "$0")")/install"
source "$INSTALL_DIR/common.sh"

MODULES=(packages root shell git emacs hyprpm wal stow gpg doom yazi ivanti)

usage() {
    echo "Usage: $(basename "$0") [<module>...|all]"
    echo ""
    echo "Without arguments, an interactive checklist (all modules checked) is shown."
    echo ""
    echo "Available modules:"
    for mod in "${MODULES[@]}"; do
        echo "  $mod"
    done
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") font git stow"
    echo "  $(basename "$0") ${MODULES[*]}"
}

is_valid_module() {
    local name="$1" mod
    for mod in "${MODULES[@]}"; do
        [[ "$mod" == "$name" ]] && return 0
    done
    return 1
}

# Interactive checklist with every module pre-checked. Fills $selected.
select_modules() {
    local n=${#MODULES[@]} cursor=0 i key rest
    local checked=()
    for ((i = 0; i < n; i++)); do checked[i]=1; done

    printf '\e[?25l' >&2
    trap 'printf "\e[?25h" >&2' EXIT
    echo "Select modules (↑/↓ or j/k move, space toggle, a all/none, enter run, q quit)" >&2

    while true; do
        for ((i = 0; i < n; i++)); do
            local mark=" " pointer=" "
            [[ ${checked[i]} -eq 1 ]] && mark="x"
            [[ $i -eq $cursor ]] && pointer=">"
            printf '\e[2K%s [%s] %s\n' "$pointer" "$mark" "${MODULES[i]}" >&2
        done

        IFS= read -rsn1 key </dev/tty
        if [[ "$key" == $'\e' ]]; then
            read -rsn2 -t 0.1 rest </dev/tty || true
            key+="$rest"
        fi
        case "$key" in
            $'\e[A'|k) cursor=$(((cursor - 1 + n) % n)) ;;
            $'\e[B'|j) cursor=$(((cursor + 1) % n)) ;;
            " ") checked[cursor]=$((1 - checked[cursor])) ;;
            a)
                local all=1
                for ((i = 0; i < n; i++)); do [[ ${checked[i]} -eq 0 ]] && all=0; done
                for ((i = 0; i < n; i++)); do checked[i]=$((1 - all)); done
                ;;
            "") break ;;
            q) exit 0 ;;
        esac
        printf '\e[%dA' "$n" >&2
    done

    printf '\e[?25h' >&2
    trap - EXIT
    selected=()
    for ((i = 0; i < n; i++)); do
        [[ ${checked[i]} -eq 1 ]] && selected+=("${MODULES[i]}")
    done
    return 0
}

selected=()
if [[ $# -eq 0 ]]; then
    if [[ ! -t 0 ]]; then
        usage
        exit 0
    fi
    select_modules
    if [[ ${#selected[@]} -eq 0 ]]; then
        log_warn "install" "No modules selected."
        exit 0
    fi
    log_step "install" "Running: ${selected[*]}"
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
elif [[ "$1" == "all" ]]; then
    selected=("${MODULES[@]}")
else
    for mod in "$@"; do
        if ! is_valid_module "$mod"; then
            log_error "install" "Unknown module: $mod"
            echo ""
            usage
            exit 1
        fi
    done
    selected=("$@")
fi

for mod in "${selected[@]}"; do
    echo ""
    source "$INSTALL_DIR/${mod}.sh"
    run
done

echo ""
log_step "install" "All done!"
