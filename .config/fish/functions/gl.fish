function gl --description 'lazygit (dotfiles bare repo if outside a git repo)'
    if git rev-parse --is-inside-work-tree &>/dev/null
        lazygit $argv
    else
        lazygit --git-dir="$HOME/.cfg" --work-tree="$HOME" $argv
    end
end
