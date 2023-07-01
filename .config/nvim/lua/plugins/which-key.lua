-- Popup for pending keybinds.
return {
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        opts = {
            window = {
                border = 'single',
            },
            disable = {
                filetypes = { 'alpha' },
            },
        },
        config = function(_, opts)
            local wk = require 'which-key'
            wk.setup(opts)

            wk.register {
                ['<leader>b'] = { name = '+buffer' },
                ['<leader>d'] = { name = '+debug' },
                ['<leader>da'] = { name = '+debug adapters' },
                ['<leader>s'] = { name = '+search' },
                ['<leader>t'] = { name = '+trouble' },
            }
        end,
    },
}
