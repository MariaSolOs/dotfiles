-- Stuff I should do.
return {
    {
        'folke/todo-comments.nvim',
        dependencies = 'nvim-lua/plenary.nvim',
        cmd = { 'TodoTrouble', 'TodoTelescope' },
        event = { 'BufReadPost', 'BufNewFile' },
        keys = {
            { '<leader>xt', ':TodoTrouble<cr>', desc = 'TODOs' },
            { '<leader>tt', ':TodoTelescope<cr>', desc = 'TODOs' },
        },
        opts = {
            signs = false,
            search = {
                pattern = [[\b(KEYWORDS)(:|!\()]],
            },
            highlight = {
                pattern = {
                    [[.*<(KEYWORDS)\s*:]],
                    [[.*<(KEYWORDS)!\(]],
                },
                after = '',
                comments_only = false,
            },
            keywords = {
                TODO = { alt = { 'todo' } },
            },
        },
    },
}
