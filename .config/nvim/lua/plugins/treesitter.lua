-- Highlight, edit, and navigate code.
return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
        lazy = true,
        build = ':TSUpdate',
        opts = {
            ensure_installed = {
                'bash',
                'json',
                'jsonc',
                'json5',
                'lua',
                'regex',
                'rust',
                'toml',
                'typescript',
                'vim',
                'vimdoc',
            },
            auto_install = false,
            highlight = { enable = true },
            indent = { enable = true },
            rainbow = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    node_incremental = '<C-o>',
                    node_decremental = '<C-i>',
                },
            },
            textobjects = {
                move = {
                    enable = true,
                    set_jumps = true,
                    goto_next_start = {
                        [']f'] = '@function.outer',
                    },
                    goto_next_end = {
                        [']F'] = '@function.outer',
                    },
                    goto_previous_start = {
                        ['[f'] = '@function.outer',
                    },
                    goto_previous_end = {
                        ['[F'] = '@function.outer',
                    },
                },
            },
        },
        config = function(_, opts)
            require('nvim-treesitter.configs').setup(opts)
        end,
    },
}
