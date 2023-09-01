-- Popup for pending keybinds.
return {
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        -- TODO: Update to the latest version when https://github.com/folke/which-key.nvim/issues/482 gets fixed.
        version = '1.4.3',
        opts = {
            window = { border = 'rounded' },
        },
        config = function(_, opts)
            local wk = require 'which-key'
            wk.setup(opts)

            wk.register {
                -- Register leader groups.
                ['<leader>c'] = { name = '+code' },
                ['<leader>d'] = { name = '+debug' },
                ['<leader>f'] = { name = '+finder' },
                ['<leader>x'] = { name = '+loclist/quickfix' },
                -- Other builtin prefixes.
                ['g'] = { name = '+goto' },
                ['z'] = { name = '+fold/scroll' },
                ['['] = { name = '+previous' },
                [']'] = { name = '+next' },
                ['='] = { name = '+put' },
            }
        end,
    },
}
