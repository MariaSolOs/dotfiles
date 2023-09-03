-- Folding ranges.
return {
    {
        'kevinhwang91/nvim-ufo',
        event = 'VeryLazy',
        dependencies = {
            'kevinhwang91/promise-async',
            -- Get rid of the numbers in the folding column.
            {
                'luukvbaal/statuscol.nvim',
                config = function()
                    local builtin = require 'statuscol.builtin'
                    require('statuscol').setup {
                        segments = {
                            { text = { builtin.foldfunc } },
                            { text = { '%s' } },
                            { text = { builtin.lnumfunc, ' ' } },
                        },
                    }
                end,
            },
        },
        keys = {
            {
                'zp',
                function()
                    require('ufo').peekFoldedLinesUnderCursor()
                end,
                desc = 'Peek folded lines under cursor',
            },
        },
        opts = {
            preview = {
                win_config = {
                    winblend = 10,
                    maxheight = 10,
                },
            },
        },
        config = function(_, opts)
            require('ufo').setup(opts)

            -- HACK: Refresh indent lines after folding/unfolding.
            for _, keys in pairs {
                'zo',
                'zO',
                'zc',
                'zC',
                'za',
                'zA',
                'zv',
                'zx',
                'zm',
                'zr',
                {
                    'zM',
                    ':lua require("ufo").closeAllFolds()<cr>',
                },
                {
                    'zR',
                    ':lua require("ufo").openAllFolds()<cr>',
                },
            } do
                local rhs = type(keys) == 'table' and keys[2] or keys
                local lhs = type(keys) == 'table' and keys[1] or keys
                vim.keymap.set('n', lhs, rhs .. '<cmd>IndentBlanklineRefresh<cr>', { noremap = true })
            end
        end,
    },
}
