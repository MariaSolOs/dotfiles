-- Popup for pending keybinds.
return {
    {
        'folke/which-key.nvim',
        opts = {
            window = {
                border = 'single',
            },
        },
        config = function(_, opts)
            local wk = require 'which-key'
            wk.setup(opts)

            wk.register {
                ['<leader>b'] = { name = '+buffer' },
                ['<leader>d'] = { name = '+debug' },
                ['<leader>da'] = { name = '+debug adapters' },
                ['<leader>g'] = { name = '+git' },
                ['<leader>s'] = { name = '+search' },
                ['<leader>t'] = { name = '+trouble' },
            }
        end,
    },
}
