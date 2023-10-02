# XDG locations.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"

# Make sure this stuff is in the path.
export PATH="$HOME/.cargo/bin:$PATH" # cargo
export PATH="$HOME/nvim/bin:$PATH" # neovim
export PATH="/usr/local/opt/tcl-tk/bin:$PATH" # tcl-tk
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH" # GNU coreutils

# Load nvm and set up bash completions.
export NVM_DIR="$XDG_CONFIG_HOME/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# zsh configuration.
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export SHELL_SESSIONS_DISABLE=1

# Man pages
export MANPAGER='nvim +Man!'

# Set up neovim as the default editor.
export EDITOR="$(which nvim)"
export VISUAL="$EDITOR"

# Disable Apple's save/restore mechanism.
export SHELL_SESSIONS_DISABLE=1

# Ripgrep.
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/.ripgreprc"

# fzf settings.
export FZF_DEFAULT_OPTS="--color=fg:#f8f8f2,bg:#000000,hl:#bd93f9,fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9,info:#f1fa8c,prompt:#50fa7b,pointer:#ff79c6,marker:#ff79c6,spinner:#a4ffff,header:#6272a4 \
--cycle"
