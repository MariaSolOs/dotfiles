-- Generate and open GitHub links.
return {
    {
        'ruifm/gitlinker.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        -- Loaded when attaching gitsigns.
        lazy = true,
        opts = { mappings = '<leader>gc' },
    },
}
