-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = 'Trouble',
    opts = {
        -- Open the list when there's a diagnostic, and close it when there's none.
        auto_open = true,
        auto_close = true
    },
    init = function(_)
        vim.keymap.set('n', '<leader>x', '<cmd>TroubleToggle<cr>',
            { silent = true, noremap = true }
        )
    end
}
