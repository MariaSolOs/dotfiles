# Make sure this stuff is in the path.
export PATH="$HOME/.cargo/bin:$PATH" # cargo
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH" # neovim version manager
export PATH="/usr/local/opt/tcl-tk/bin:$PATH" # tcl-tk

# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Plugins.
plugins=(
    colored-man-pages # Add colors to man pages
    command-not-found # Provide suggested packages to be installed if a command cannot be found
    git # git aliases and functions
    nvm
    rust
    yarn
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Load nvm and set up bash completions.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python setup.
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Set up the starshipt prompt.
eval "$(starship init zsh)"

# Git aliases for my dotfiles repo.
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
# Idk why but I couldn't use the config alias below.
alias cs='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME status'
alias ca='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME add'
alias cc='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME commit -m'
