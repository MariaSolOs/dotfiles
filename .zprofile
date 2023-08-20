# XDG locations.
export XDG_DATA_HOME="$HOME/.local/share"

# Make sure this stuff is in the path.
export PATH="$HOME/.cargo/bin:$PATH" # cargo
export PATH="$XDG_DATA_HOME/bob/nvim-bin:$PATH" # neovim version manager
export PATH="/usr/local/opt/tcl-tk/bin:$PATH" # tcl-tk

# Ripgrep.
export RIPGREP_CONFIG_PATH="$HOME/.config/.ripgreprc"

# Homebrew variables.
eval "$(/opt/homebrew/bin/brew shellenv)"
