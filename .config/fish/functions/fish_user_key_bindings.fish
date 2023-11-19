function fish_user_key_bindings
    # Use emacs bindings in insert mode, using vi bindings if there's a conflict.
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert

    # Keep the same history navigation bindings.
    bind \cp up-or-search
    bind \cn down-or-search

    # Copy/paste.
    bind yy fish_clipboard_copy
    bind p fish_clipboard_paste

    # fzf bindings.
    fzf_key_bindings
end
