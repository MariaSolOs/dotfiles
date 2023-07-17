-- Popup for pending keybinds.
return {
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        -- TODO: Update to the latest version when the register bug gets fixed.
        version = '1.4.3',
        opts = {
            window = {
                border = 'rounded',
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
                ['<leader>c'] = { name = '+code' },
                ['<leader>d'] = { name = '+debug' },
                ['<leader>da'] = { name = '+debug adapters' },
                ['<leader>t'] = { name = '+telescope' },
                ['<leader>x'] = { name = '+trouble' },
            }
        end,
    },
}
