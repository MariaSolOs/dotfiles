-- Popup for pending keybinds.
return {
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        -- TODO: Update to the latest version when https://github.com/folke/which-key.nvim/issues/482 gets fixed.
        version = '1.4.3',
        opts = {
            show_help = false,
            window = { border = 'rounded' },
            icons = { breadcrumb = '', separator = '' },
            -- Also wait for marks.
            triggers_nowait = { '"', '<c-r>', 'z=' },
        },
        config = function(_, opts)
            local wk = require 'which-key'

            wk.setup(opts)

            wk.register {
                -- Register leader groups.
                ['<leader>b'] = { name = '+buffers' },
                ['<leader>c'] = { name = '+code' },
                ['<leader>d'] = { name = '+debug' },
                ['<leader>f'] = { name = '+finder' },
                ['<leader>p'] = { name = '+tabs' },
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
