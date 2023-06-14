-- Pretty list for diagnostics, references, etc.
return {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = { 'Trouble', 'TroubleToggle' },
    opts = {
        action_keys = {
            -- When opening a diagnostic with <Enter>, close the list.
            jump_close = '<cr>'
        }
    },
    init = function(_)
        vim.keymap.set('n', '<leader>xd', '<cmd>TroubleToggle workspace_diagnostics<cr>',
            { silent = true, noremap = true }
        )
    end
}
