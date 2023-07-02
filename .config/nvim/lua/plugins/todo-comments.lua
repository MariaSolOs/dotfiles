-- TODO comments.
return {
    'folke/todo-comments.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = { 'BufReadPost', 'BufNewFile' },
    keys = {
        { '<leader>tt', ':TodoTelescope<cr>', desc = 'TODOs' },
    },
    opts = {
        signs = false,
    },
}
