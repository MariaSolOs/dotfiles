-- Highlight, edit, and navigate code.
return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
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
            },
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ['af'] = '@function.outer',
                        ['if'] = '@function.inner'
                    }
                },
                move = {
                    enable = true,
                    set_jumps = true,
                    goto_next_start = {
                        [']m'] = '@function.outer'
                    },
                    goto_next_end = {
                        [']M'] = '@function.outer'
                    },
                    goto_previous_start = {
                        ['[m'] = '@function.outer'
                    },
                    goto_previous_end = {
                        ['[M'] = '@function.outer'
                    },
                },
            }
        },
        config = function(_, opts)
            require('nvim-treesitter.configs').setup(opts)
        end
    }
}
