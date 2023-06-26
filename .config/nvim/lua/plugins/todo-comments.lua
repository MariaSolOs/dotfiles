-- TODO comments.
return {
    'folke/todo-comments.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = { 'BufReadPost', 'BufNewFile' },
    config = true,
    keys = {
        { '<leader>tt', ':TodoTrouble<cr>', desc = 'TODOs' },
        { '<leader>st', ':TodoTelescope<cr>', desc = 'Search TODOs' },
    },
}
