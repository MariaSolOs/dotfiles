-- Highlight, edit, and navigate code.
return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            {
                'nvim-treesitter/nvim-treesitter-textobjects',
                init = function()
                    -- Disable the rtp plugin, as we only need its queries for mini.ai.
                    require('lazy.core.loader').disable_rtp_plugin 'nvim-treesitter-textobjects'
                end,
            },
            {
                'nvim-treesitter/nvim-treesitter-context',
                opts = {
                    -- Avoid the sticky context from growing a lot.
                    max_lines = 3,
                    -- Match the context lines to the source code.
                    multiline_threshold = 1,
                },
                keys = {
                    {
                        '[c',
                        function()
                            require('treesitter-context').go_to_context()
                        end,
                        desc = 'Jump to upper context',
                    },
                },
            },
        },
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
                'python',
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
        },
        config = function(_, opts)
            require('nvim-treesitter.configs').setup(opts)
        end,
    },
}
