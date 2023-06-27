-- TODO comments.
return {
    'folke/todo-comments.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = { 'BufReadPost', 'BufNewFile' },
    keys = {
        { '<leader>tt', ':TodoTrouble<cr>', desc = 'TODOs' },
        { '<leader>st', ':TodoTelescope<cr>', desc = 'Search TODOs' },
    },
    config = true,
}
