-- Tab out from parentheses, quotes, etc.
return {
    {
        'abecodes/tabout.nvim',
        event = 'InsertEnter',
        dependencies = { 'nvim-treesitter', 'nvim-cmp' },
        config = true,
    },
}
