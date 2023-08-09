# XDG locations.
export XDG_DATA_HOME="$HOME/.local/share"

# Make sure this stuff is in the path.
export PATH="$HOME/.cargo/bin:$PATH" # cargo
export PATH="$XDG_DATA_HOME/bob/nvim-bin:$PATH" # neovim version manager
export PATH="/usr/local/opt/tcl-tk/bin:$PATH" # tcl-tk

# Homebrew variables.
eval "$(/opt/homebrew/bin/brew shellenv)"
