function config --wraps='/usr/bin/git --git-dir="$HOME/.cfg" --work-tree="$HOME"' --description 'git - Dotfiles'
  /usr/bin/git --git-dir="$HOME/.cfg" --work-tree="$HOME" $argv
end
