-- Stuff I should do.
return {
    {
        'folke/todo-comments.nvim',
        dependencies = 'nvim-lua/plenary.nvim',
        cmd = 'TodoTrouble',
        event = { 'BufReadPost', 'BufNewFile' },
        keys = {
            { '<leader>xt', '<cmd>TodoTrouble<cr>', desc = 'TODOs' },
        },
        opts = {
            signs = false,
            search = {
                pattern = [[\b(KEYWORDS)(:|!?\(.*\))]],
            },
            highlight = {
                pattern = {
                    [[.*(KEYWORDS):]],
                    [[.*(KEYWORDS)!?\(.*\)]],
                },
                after = '',
                -- For also highlighting Rust todo macros.
                comments_only = false,
            },
            keywords = {
                FIX = { icon = ' ', color = 'error', alt = { 'FIXME', 'BUG', 'ISSUE' } },
                TODO = { icon = ' ', color = 'info', alt = { 'todo' } },
                WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
                NOTE = { icon = ' ', color = 'hint', alt = { 'INFO' } },
            },
            -- Just use the keywords defined above.
            merge_keywords = false,
        },
    },
}
