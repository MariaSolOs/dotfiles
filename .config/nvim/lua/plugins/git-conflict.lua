-- Resolve and visualize git conflicts.
return {
    {
        'akinsho/git-conflict.nvim',
        lazy = true,
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
