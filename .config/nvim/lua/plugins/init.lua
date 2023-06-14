return {
    -- Git wrapper.
    { 'tpope/vim-fugitive' },

    -- Popup for pending keybinds.
    { 'folke/which-key.nvim', opts = {} },

    -- "gc" to comment visual regions/lines.
    {
        'numToStr/Comment.nvim',
        opts = {
            extra = { above = 'gch', below = 'gcl' }
        },
        event = 'VeryLazy'
    },

    -- Icons used by a bunch of UI extensions.
    { 'nvim-tree/nvim-web-devicons', lazy = true },

    -- Highlight colors.
    { 'norcalli/nvim-colorizer.lua', config = true,      ft = 'lua',   opts = { 'lua' } },

    -- Surround selections, add quotes, etc.
    { 'kylechui/nvim-surround',      event = 'VeryLazy', config = true }
}
