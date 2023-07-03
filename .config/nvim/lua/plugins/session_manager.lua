-- Session management.
return {
    {
        'Shatur/neovim-session-manager',
        cmd = 'SessionManager',
        config = function()
            local cfg = require 'session_manager.config'

            require('session_manager').setup {
                autoload_mode = cfg.AutoloadMode.Disabled,
                autosave_ignore_dirs = { '~/.config/nvim' },
            }
        end,
    },
}
