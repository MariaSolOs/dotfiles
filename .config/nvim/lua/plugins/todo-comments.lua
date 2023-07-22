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
                -- For also highlighting Rust todo macros.
                comments_only = false,
            },
            keywords = {
                FIX = { icon = ' ', color = 'error', alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' } },
                TODO = { icon = ' ', color = 'info', alt = { 'todo' } },
                WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
                PERF = { icon = ' ', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
                NOTE = { icon = ' ', color = 'hint', alt = { 'INFO' } },
            },
            -- Just use the keywords defined above.
            merge_keywords = false,
        },
    },
}
