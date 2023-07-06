-- Highlight, edit, and navigate code.
return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = 'nvim-treesitter/nvim-treesitter-textobjects',
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
                'javascript',
                'json',
                'jsonc',
                'json5',
                'lua',
                'markdown',
                'markdown_inline',
                'regex',
                'rust',
                'toml',
                'typescript',
                'vim',
                'vimdoc',
            },
            highlight = {
                enable = true,
                disable = function(lang, buf)
                    -- Looking at you checker.ts
                    return lang == 'typescript' and vim.api.nvim_buf_line_count(buf) > 10000
                end,
            },
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
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ['af'] = '@function.outer',
                        ['if'] = '@function.inner',
                    },
                },
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
