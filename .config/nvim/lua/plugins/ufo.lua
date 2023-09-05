-- Folding ranges.
return {
    {
        'kevinhwang91/nvim-ufo',
        event = 'VeryLazy',
        dependencies = {
            'kevinhwang91/promise-async',
            -- Get rid of the numbers in the folding column.
            -- TODO: Remove this plugin if support for doing this with just the
            -- built-in options is added to Neovim.
            {
                'luukvbaal/statuscol.nvim',
                opts = function()
                    local builtin = require 'statuscol.builtin'
                    return {
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
            {
                'zM',
                function()
                    require('ufo').closeAllFolds()
                end,
                desc = 'Close all folds',
            },
            {
                'zR',
                function()
                    require('ufo').openAllFolds()
                end,
                desc = 'Open all folds',
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
    },
}
