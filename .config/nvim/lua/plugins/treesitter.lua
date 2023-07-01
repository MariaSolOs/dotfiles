-- Highlight, edit, and navigate code.
return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects', 'HiPhish/nvim-ts-rainbow2' },
        version = false,
        event = { 'BufReadPost', 'BufNewFile' },
        build = ':TSUpdate',
        keys = {
            { '<cr>', desc = 'Increment selection' },
            { '<bs>', desc = 'Decrement selection', mode = 'x' },
        },
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
            highlight = { enable = true },
            rainbow = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = '<cr>',
                    node_incremental = '<cr>',
                    scope_incremental = false,
                    node_decremental = '<bs>',
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
