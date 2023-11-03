function clazy --wraps='lazygit --git-dir="$HOME/.cfg" --work-tree="$HOME"' --description 'lazygit - Dotfiles'
  lazygit --git-dir="$HOME/.cfg" --work-tree="$HOME" $argv
end
