# Make sure this stuff is in the path.
export PATH="$HOME/.cargo/bin:$PATH" # cargo
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH" # neovim version manager
export PATH="/usr/local/opt/tcl-tk/bin:$PATH" # tcl-tk

# Auto-cd if the command is a directory and can't be executed as a normal command.
setopt auto_cd

# Command history.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups # ignore duplicated commands history list

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

# Functions for completion sources.
fpath+=~/.zsh/func
autoload -Uz compinit
compinit

# Use a completion menu.
zstyle ':completion:*' menu select

# Colorize completions using default ls colors. 
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Colored commands.
alias ls='ls --color=auto'

# General git aliases.
alias ga='git add'
alias gb='git branch'
alias gc='git commit --verbose'
alias gco='git checkout'
alias gl='git log'
alias gp='git push'
alias gst='git status'

# Git aliases for my dotfiles repo.
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
# Idk why but I couldn't use the config alias below.
alias cs='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME status'
alias ca='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME add'
alias cc='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME commit -m'

# Auto-suggestions.
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting (must be at the end of this file).
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
