-- Folding ranges.
return {
    {
        'kevinhwang91/nvim-ufo',
        event = 'VeryLazy',
        dependencies = 'kevinhwang91/promise-async',
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
                    winblend = 5,
                    maxheight = 10,
                },
            },
        },
    },
}
