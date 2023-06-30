-- Session management.
return {
    {
        'Shatur/neovim-session-manager',
        cmd = 'SessionManager',
        dependencies = { 'nvim-lua/plenary.nvim', 'dressing.nvim' },
        keys = {
            { '<leader>ssl', ':SessionManager load_session<cr>', desc = 'Load session' },
            { '<leader>ssd', ':SessionManager delete_session<cr>', desc = 'Delete session' },
        },
        config = function()
            local cfg = require 'session_manager.config'

            require('session_manager').setup {
                autoload_mode = cfg.AutoloadMode.Disabled,
            }
        end,
    },
}
