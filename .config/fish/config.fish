# Nothing to do if not inside an interactive shell.
if not status is-interactive
    return 0
end

# Set up Ghostty's shell integration.
if test -n "$GHOSTTY_RESOURCES_DIR"
    source $GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
end

# Figure out which operating system we're in.
set -l os (uname)

# Neovim.
abbr -a nv nvim
abbr -a nvo --set-cursor "cd % && nvim"
abbr -a nvp nvim +Man!

# Git abbreviations.
abbr -a g git
abbr -a ga git add
abbr -a gb git branch
abbr -a gc git commit --verbose
abbr -a gco git checkout
abbr -a gf git fetch
abbr -a gl lazygit
abbr -a gm git merge
abbr -a gpl git pull
abbr -a gpu git push
abbr -a gst git status

# System maintenance.
abbr -a --position anywhere s sudo
if test "$os" = Darwin
    abbr -a --position anywhere b brew
else if test "$os" = Linux
    abbr -a j journalctl
    abbr -a pc --position anywhere pacman
end

# Add completions from stuff installed with Homebrew.
if test "$os" = Darwin
    if test -d (brew --prefix)"/share/fish/completions"
        set -p fish_complete_path (brew --prefix)/share/fish/completions
    end
    if test -d (brew --prefix)"/share/fish/vendor_completions.d"
        set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
    end
end

# Remove the gretting message.
set -U fish_greeting

# Vi mode.
set -g fish_key_bindings fish_vi_key_bindings
set fish_vi_force_cursor 1
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore

# fzf shell integration:
fzf --fish | source

# Color theme.
fish_config theme choose "Dracula Official"

# Prompt.
if test "$os" = Darwin
    starship init fish | source
else if test "$os" = Linux
    # Set the prompt when inside Hyprland.
    if set -q HYPRLAND_INSTANCE_SIGNATURE
        starship init fish | source
    end
end
