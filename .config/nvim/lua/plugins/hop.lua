return {
    {
        'phaazon/hop.nvim',
        branch = 'v2',
        opts = {},
        init = function(_)
            vim.keymap.set({ 'n' }, '<leader>c', '<cmd>HopChar1<cr>', { desc = 'Hop anywhere', silent = true })
            vim.keymap.set({ 'n' }, '<leader>l', '<cmd>HopLineStart<cr>', { desc = 'Hop to a line', silent = true })
            vim.keymap.set({ 'n' }, '<leader>w', '<cmd>HopWord<cr>', { desc = 'Hop to a word', silent = true })
        end
    },
}
