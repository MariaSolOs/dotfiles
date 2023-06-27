-- Plugins with a simple enough config that don't deserve their own file.
return {
    -- Toggle relative line numbers in normal mode.
    { 'sitiom/nvim-numbertoggle' },

    -- Autoclosing braces.
    {
        'windwp/nvim-autopairs',
        event = 'InsertEnter',
        config = true,
    },

    -- Highlight colors.
    {
        'norcalli/nvim-colorizer.lua',
        ft = { 'lua', 'conf' },
        -- stylua: ignore
        opts = { 'lua'; 'conf' },
    },

    -- Surround selections, add quotes, etc.
    {
        'kylechui/nvim-surround',
        event = 'VeryLazy',
        opts = {
            keymaps = {
                visual = 'Y',
            },
        },
    },

    -- 'gc' to comment visual regions/lines.
    {
        'numToStr/Comment.nvim',
        event = 'VeryLazy',
        opts = {
            extra = { above = 'gch', below = 'gcl' },
        },
    },
}
