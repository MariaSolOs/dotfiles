# Auto-cd if the command is a directory and can't be executed as a normal command.
setopt auto_cd

# When deleting with <C-w>, delete file names at a time.
WORDCHARS=${WORDCHARS/\/}

# Complete a single word with <Ctrl+Left>, and the full thing with <Left>.
bindkey '^[[1;5C' forward-word

# Delete duplicates first when HISTFILE size exceeds HISTSIZE.
setopt hist_expire_dups_first

# Ignore duplicated commands history list.
setopt hist_ignore_dups

# Completion for kitty
if [[ "$TERM" == "xterm-kitty" ]]; then
  kitty + complete setup zsh | source /dev/stdin
fi

# Load nvm and set up bash completions.
# TODO: Move this inside .config
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python setup.
# TODO: Move this inside .config
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Set up the starshipt prompt.
eval "$(starship init zsh)"

# Functions for completion sources.
fpath=($ZDOTDIR/func $fpath)
fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
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
alias gf='git fetch'
alias gl='git log'
alias gm='git merge'
alias gp='git push'
alias gst='git status'

# Git aliases for my dotfiles repo.
function config() {
    /usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME" "$@"
}
alias cs='config status'
alias ca='config add'
alias cc='config commit -m'
alias cp='config push'
alias cdiff='config diff'
alias cl='config log'

# fzf.
source "$ZDOTDIR/.fzf.zsh"

# Auto-suggestions.
source "$ZDOTDIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Auto-close, delete and skip over matching delimiters.
source "$ZDOTDIR/zsh-autopair/autopair.zsh"
autopair-init

# Syntax highlighting (must be at the end of this file).
source "$ZDOTDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
