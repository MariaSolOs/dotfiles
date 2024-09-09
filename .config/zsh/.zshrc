# Auto-cd if the command is a directory and can't be executed as a normal command.
setopt auto_cd

# When deleting with <C-w>, delete file names at a time.
WORDCHARS=${WORDCHARS/\/}

# Delete duplicates first when HISTFILE size exceeds HISTSIZE.
setopt hist_expire_dups_first

# Share history between windows.
setopt SHARE_HISTORY

# Ignore duplicated commands history list.
setopt hist_ignore_dups

# Load nvm and set up bash completions.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python setup.
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Functions for completion sources.
fpath=($ZDOTDIR/func $fpath)
fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
autoload -Uz compinit
compinit

# Use a completion menu.
zstyle ':completion:*' menu select

# Custom aliases.
source "$ZDOTDIR/aliases.zsh"

# Execute fish if it's not the parent process.
if ! ps -p $PPID | grep -q fish; then
  fish
fi
