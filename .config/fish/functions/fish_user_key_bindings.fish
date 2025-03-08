function fish_user_key_bindings
    # Use emacs bindings in insert mode, using vi bindings if there's a conflict.
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert

    # Keep the same history navigation bindings.
    bind \cp up-or-search
    bind \cn down-or-search

    # Replace !! by the previous command.
    bind -M insert ! bind_bang

    # Use <C-Slash> to clear the line.
    bind -M insert \c_ kill-whole-line repaint
end
