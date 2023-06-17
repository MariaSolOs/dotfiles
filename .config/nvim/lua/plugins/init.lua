-- Plugins with a simple enough config
-- that don't deserve their own file.
return {
    -- 'gc' to comment visual regions/lines.
    {
        'numToStr/Comment.nvim',
        opts = {
            extra = { above = 'gch', below = 'gcl' },
        },
        event = 'VeryLazy',
    },

    -- Icons used by a bunch of UI extensions.
    { 'nvim-tree/nvim-web-devicons', lazy = true },

    -- Highlight colors.
    {
        'norcalli/nvim-colorizer.lua',
        event = 'VeryLazy',
        opts = { 'lua' },
    },

    -- Surround selections, add quotes, etc.
    { 'kylechui/nvim-surround',      event = 'VeryLazy', config = true },

    -- Toggle relative line numbers in normal mode.
    { 'sitiom/nvim-numbertoggle' },
}
