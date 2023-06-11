return {
    {
        'phaazon/hop.nvim',
        branch = 'v2',
        opts = {},
        init = function(_)
            vim.keymap.set({ 'n' }, '<leader>c', ':HopChar1<cr>', { desc = 'Hop anywhere', silent = true })
            vim.keymap.set({ 'n' }, '<leader>l', ':HopLineStart<cr>', { desc = 'Hop to a line', silent = true })
            vim.keymap.set({ 'n' }, '<leader>w', ':HopWord<cr>', { desc = 'Hop to a word', silent = true })
        end
    },
}
