# Auto-cd if the command is a directory and can't be executed as a normal command.
setopt auto_cd

# When deleting with <C-w>, delete file names at a time.
WORDCHARS=${WORDCHARS/\/}

# Command history.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups # ignore duplicated commands history list

# Set up neovim as the default editor.
export EDITOR="$(which nvim)"

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
fpath+="$(brew --prefix)/share/zsh/site-functions"
autoload -Uz compinit
compinit

# Setup fzf.
[ -f ~/.zsh/.fzf.zsh ] && source ~/.zsh/.fzf.zsh
export FZF_DEFAULT_OPTS='--color=fg:#f8f8f2,bg:#000000,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#f1fa8c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#a4ffff,header:#6272a4'

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
alias gf='git fetch'
alias gl='git log'
alias gm='git merge'
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
