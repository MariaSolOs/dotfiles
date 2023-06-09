return {
    {
        'phaazon/hop.nvim',
        branch = 'v2',
        opts = {},
        init = function(_)
            vim.keymap.set({ 'n' }, '<leader>h', ':HopAnywhereCurrentLine<cr>',
                { desc = 'Hop in the current line', silent = true })
        end
    },
}
