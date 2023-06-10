-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = 'Trouble',
    init = function(_)
        vim.keymap.set('n', '<leader>x', '<cmd>TroubleToggle<cr>',
            { silent = true, noremap = true }
        )
    end
}
