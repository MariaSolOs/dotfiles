return {
    {
        -- Highlight, edit, and navigate code.
        'nvim-treesitter/nvim-treesitter',
        lazy = true,
        build = ':TSUpdate',
        opts = {
            ensure_installed = { 'lua', 'rust', 'typescript', 'vim', 'vimdoc' },
            auto_install = false,
            highlight = { enable = true },
            indent = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    node_incremental = '<C-o>',
                    node_decremental = '<C-i>',
                },
            }
        },
        config = function(_, opts)
            require('nvim-treesitter.configs').setup(opts)
        end
    }
}
