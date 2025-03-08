function fish_user_key_bindings
    # Use emacs bindings in insert mode, using vi bindings if there's a conflict.
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert

    # Make sure ctrl-n still works in insert mode.
    bind -M insert ctrl-n down-or-search

    # Replace !! by the previous command.
    bind -M insert ! bind_bang
end
