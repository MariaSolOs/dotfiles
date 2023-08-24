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
                'zR',
                function()
                    require('ufo').openAllFolds()
                    vim.cmd 'IndentBlanklineRefresh'
                end,
            },
            {
                'zM',
                function()
                    require('ufo').closeAllFolds()
                    vim.cmd 'IndentBlanklineRefresh'
                end,
            },
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
            -- Automatically close imports/comments when first loading the buffer.
            close_fold_kinds = { 'imports', 'comment' },
        },
        config = function(_, opts)
            require('ufo').setup(opts)

            -- HACK: Refresh indent lines after folding/unfolding.
            local function keymap(lhs, rhs)
                vim.keymap.set('n', lhs, rhs, { noremap = true })
            end
            for _, lhs in pairs {
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
            } do
                keymap(lhs, lhs .. '<cmd>IndentBlanklineRefresh<cr>')
            end

            -- Add a label to which-key for all these mappings.
            require('which-key').register {
                ['z'] = { name = '+fold/scroll' },
            }
        end,
    },
}
