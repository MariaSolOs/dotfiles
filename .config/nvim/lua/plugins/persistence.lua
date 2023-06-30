-- Session management.
return {
    {
        'folke/persistence.nvim',
        event = 'BufReadPre',
        config = true,
    },
}
