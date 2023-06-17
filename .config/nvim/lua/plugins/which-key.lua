-- Popup for pending keybinds.
return {
    {
        'folke/which-key.nvim',
        opts = function()
            require('which-key').register {
                ['<leader>b'] = { name = '+buffer' },
                ['<leader>d'] = { name = '+debug' },
                ['<leader>g'] = { name = '+git' },
                ['<leader>da'] = { name = '+debug adapters' },
                ['<leader>s'] = { name = '+search' },
                ['<leader>t'] = { name = '+trouble' },
            }
        end,
    },
}
