-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
        -- When opening a diagnostic with <Enter>, close the list.
        action_keys = {
            jump_close = '<cr>'
        }
    },
    config = function(_, opts)
        require('trouble').setup(opts)

        vim.keymap.set('n', '<leader>xd', '<cmd>TroubleToggle workspace_diagnostics<cr>',
            { silent = true, noremap = true }
        )
    end
}
