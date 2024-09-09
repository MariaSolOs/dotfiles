# XDG base directories.
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_PICTURES_DIR="$HOME/Pictures"
export XDG_STATE_HOME="$HOME/.local/state"

# Make sure this stuff is in the path.
export PATH="$HOME/.local/bin:$PATH" # Local scripts
export PATH="$HOME/.fzf/bin:$PATH" # fzf

# SSH agent.
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Use neovim as the default editor.
export EDITOR=nvim
export VISUAL=nvim

# Colorful sudo prompt.
SUDO_PROMPT="$(tput setaf 2 bold)Password: $(tput sgr0)" && export SUDO_PROMPT

# Man pages.
export MANPAGER='nvim +Man!'

# Ripgrep.
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/.ripgreprc"

# fzf setup.
export FZF_DEFAULT_OPTS="--color=fg:#f8f8f2,bg:#0e1419,hl:#e11299,fg+:#f8f8f2,bg+:#44475a,hl+:#e11299,info:#f1fa8c,prompt:#50fa7b,pointer:#ff79c6,marker:#ff79c6,spinner:#a4ffff,header:#6272a4 \
--cycle --pointer=▎ --marker=▎"
eval "$(fzf --bash)"

# Set the screenshots directory.
export GRIM_DEFAULT_DIR="$XDG_PICTURES_DIR/Screenshots"

# If not running interactively, stop here.
[[ $- != *i* ]] && return

# Cargo setup.
. "$HOME/.cargo/env"

# Start Hyprland on TTY1.
if [[ "$(tty)" == "/dev/tty1" ]]; then
    exec Hyprland
fi

# Drop into fish if:
# - The parent process isn't fish.
# - Not running a command like `bash -c 'echo foo'`.
if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} ]]; then
  # Let fish whether it's a login shell.
  if ! shopt -q login_shell; then
    exec fish --login
  else
    exec fish
  fi
fi
