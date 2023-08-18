-- Resolve and visualize git conflicts.
-- TODO: Use Trouble instead of the quicklist (https://github.com/akinsho/git-conflict.nvim/issues/61)
return {
    {
        'akinsho/git-conflict.nvim',
        event = 'VeryLazy',
        opts = {
            default_mappings = {
                ours = '<leader>go',
                theirs = '<leader>gt',
                none = '<leader>g0',
                both = '<leader>ga',
                prev = '[x',
                next = ']x',
            },
            disable_diagnostics = true,
        },
    },
}
