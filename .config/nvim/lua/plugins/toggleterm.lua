-- Terminal emulator.
return {
    {
        'akinsho/toggleterm.nvim',
        version = '*',
        config = true,
        cmd = 'ToggleTerm',
        init = function(_)
            vim.keymap.set({ 'n' }, '<leader>tt', ':ToggleTerm<cr>', { desc = 'Toggle terminal' })
            vim.keymap.set({ 't' }, '<leader>tt', '<C-\\><C-n>', { desc = 'Switch to normal mode' })
        end
    }
}
