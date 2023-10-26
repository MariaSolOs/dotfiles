function config --wraps=/usr/bin/git\\\ --git-dir=\"\$HOME/.cfg/\"\\\ --work-tree=\"\$HOME\" --wraps='/usr/bin/git --git-dir=/Users/majosolano/.cfg/ --work-tree=/Users/majosolano' --description 'alias config=/usr/bin/git --git-dir=/Users/majosolano/.cfg/ --work-tree=/Users/majosolano'
  /usr/bin/git --git-dir=/Users/majosolano/.cfg/ --work-tree=/Users/majosolano $argv
        
end
