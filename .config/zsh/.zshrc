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

# Completion for kitty.
if [[ "$TERM" == "xterm-kitty" ]]; then
  kitty + complete setup zsh | source /dev/stdin
fi

# Python setup.
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

# Custom aliases.
source "$ZDOTDIR/aliases.zsh"

# Custom functions.
source "$ZDOTDIR/functions.zsh"

# Vim mode. After setting it up, load other plugins to avoid keymap conflicts.
source "$(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
function zvm_after_init() {
  # Complete a single word with <Ctrl+Right>, and the full thing with <Ctrl+Space>.
  bindkey '^[[1;5C' forward-word
  bindkey '^ ' autosuggest-accept

  # fzf.
  source "$ZDOTDIR/fzf.zsh"

  # Auto-suggestions.
  source "$ZDOTDIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

  # Auto-close, delete and skip over matching delimiters.
  source "$ZDOTDIR/zsh-autopair/autopair.zsh"
  autopair-init
}

# Syntax highlighting (must be at the end of this file).
source "$ZDOTDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
