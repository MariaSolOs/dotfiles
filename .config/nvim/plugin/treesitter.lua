local add = require('vim-pack').add
local on_plugin_update = require('vim-pack').on_plugin_update

-- Highlight, edit, and navigate code.
add {
    {
        src = 'nvim-treesitter/nvim-treesitter',
        opts = {},
        on_setup = function()
            -- Make sure that the following are installed:
            require('nvim-treesitter').install {
                'bash',
                'c',
                'cpp',
                'fish',
                'gitcommit',
                'go',
                'graphql',
                'html',
                'hyprlang',
                'java',
                'javascript',
                'json',
                'json5',
                'lua',
                'markdown',
                'markdown_inline',
                'python',
                'query',
                'rasi',
                'regex',
                'rust',
                'scss',
                'toml',
                'tsx',
                'typescript',
                'vim',
                'vimdoc',
                'yaml',
            }
        end,
    },
    {
        src = 'nvim-treesitter/nvim-treesitter-context',
        module_name = 'treesitter-context',
        opts = {
            -- Avoid the sticky context from growing a lot.
            max_lines = 3,
            -- Match the context lines to the source code.
            multiline_threshold = 1,
            -- Disable it when the window is too small.
            min_window_height = 20,
        },
        on_setup = function()
            vim.keymap.set('n', '[c', function()
                -- Jump to previous change when in diffview.
                if vim.wo.diff then
                    return '[c'
                else
                    vim.schedule(function()
                        require('treesitter-context').go_to_context()
                    end)
                    return '<Ignore>'
                end
            end, { desc = 'Jump to upper context', expr = true })
        end,
    },
}

on_plugin_update('nvim-treesitter', function()
    vim.cmd 'TSUpdate'
end)
