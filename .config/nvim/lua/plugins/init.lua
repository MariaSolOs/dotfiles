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

    -- Toggle relative numbers.
    { 'sitiom/nvim-numbertoggle' },

    { 'nvim-tree/nvim-web-devicons', lazy = true },

    -- Highlight colors.
    { 'norcalli/nvim-colorizer.lua', config = true, ft = 'lua', opts = { 'lua' } }
}
