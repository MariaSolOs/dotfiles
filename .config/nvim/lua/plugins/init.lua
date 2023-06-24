-- Plugins with a simple enough config
-- that don't deserve their own file.
return {
    -- Icons used by a bunch of UI extensions.
    { 'nvim-tree/nvim-web-devicons', lazy = true },

    -- Toggle relative line numbers in normal mode.
    { 'sitiom/nvim-numbertoggle' },

    -- Autoclosing braces.
    {
        'windwp/nvim-autopairs',
        event = 'InsertEnter',
        config = true,
    },
}
