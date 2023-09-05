# Colored commands.
alias ls='ls --color=auto'

# Nvim.
alias nvimconfig="cd $XDG_CONFIG_HOME/nvim && nvim"

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
alias clazy="lazygit --git-dir=$HOME/.cfg/ --work-tree=$HOME"
