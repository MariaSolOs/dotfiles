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

            -- Add keymap descriptions to the folding commands I use.
            local descs = {}
            for _, clue in ipairs(require('mini.clue').gen_clues.z()) do
                descs[clue.keys] = clue.desc
            end
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
                vim.keymap.set(
                    'n',
                    lhs,
                    rhs .. '<cmd>IndentBlanklineRefresh<cr>',
                    { noremap = true, desc = descs[lhs] }
                )
            end
        end,
    },
}
