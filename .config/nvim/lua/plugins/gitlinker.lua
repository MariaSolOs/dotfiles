-- Generate and open GitHub links.
return {
    {
        'linrongbin16/gitlinker.nvim',
        opts = {},
        keys = {
            { '<leader>gc', '<cmd>GitLink<cr>', mode = { 'n', 'v' }, desc = 'Yank git link' },
            { '<leader>go', '<cmd>GitLink! blame<cr>', mode = { 'n', 'v' }, desc = 'Open git link' },
        },
    },
}
