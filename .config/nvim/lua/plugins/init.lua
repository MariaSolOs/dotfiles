-- Plugins with a simple enough config
-- that don't deserve their own file.
return {
    -- Icons used by a bunch of UI extensions.
    { 'nvim-tree/nvim-web-devicons', lazy = true },

    -- Toggle relative line numbers in normal mode.
    { 'sitiom/nvim-numbertoggle' },

    -- Rainbow brackets.
    {
        'HiPhish/nvim-ts-rainbow2',
        dependencies = 'nvim-treesitter/nvim-treesitter',
    },
}
