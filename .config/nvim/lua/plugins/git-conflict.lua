-- Resolve and visualize git conflicts.
return {
    {
        'akinsho/git-conflict.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            default_mappings = {
                ours = '<leader>g1',
                theirs = '<leader>g2',
                none = '<leader>g0',
                both = '<leader>g3',
                prev = '[x',
                next = ']x',
            },
            disable_diagnostics = true,
        },
    },
}
