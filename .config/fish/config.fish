# Nothing to do if not inside an interactive shell.
if not status is-interactive
    return 0
end

# Neovim.
abbr -a nv nvim
abbr -a nvconfig "cd $XDG_CONFIG_HOME/nvim && nvim"

# General git abbreviations.
abbr -a ga git add
abbr -a gb git branch
abbr -a gc git commit --verbose
abbr -a gco git checkout
abbr -a gf git fetch
abbr -a gl git log
abbr -a gm git merge
abbr -a gp git push
abbr -a gst git status

# Remove the gretting message.
set -U fish_greeting

# Vi mode.
set -g fish_key_bindings fish_vi_key_bindings
set fish_vi_force_cursor 1
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore

# Color theme.
fish_config theme choose "Dracula Official"

# Prompt.
starship init fish | source
