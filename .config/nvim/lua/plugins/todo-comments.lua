-- TODO comments.
return {
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = { 'BufReadPost', 'BufNewFile' },
    config = true,
    keys = {
        { '<leader>xt', ':TodoTrouble<cr>' },
        { '<leader>st', ':TodoTelescope<cr>' }
    }
}
