local add = require('vim-pack').add
local on_plugin_update = require('vim-pack').on_plugin_update

local parsers = {
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

-- Highlight, edit, and navigate code.
add {
    {
        src = 'nvim-treesitter/nvim-treesitter',
        on_setup = function()
            -- Main-branch nvim-treesitter ships queries under `runtime/queries/`,
            -- which isn't on rtp by default. Prepend it so highlights/folds/indents
            -- are visible to `vim.treesitter.start`.
            local init = vim.api.nvim_get_runtime_file('lua/nvim-treesitter/init.lua', false)[1]
            if init then
                vim.opt.runtimepath:prepend(vim.fn.fnamemodify(init, ':h:h:h') .. '/runtime')
            end

            require('nvim-treesitter').install(parsers):wait(300000)
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
    -- Re-install (picks up any newly-added parsers from the list above)
    -- and update existing ones.
    require('nvim-treesitter').install(parsers):wait(300000)
    require('nvim-treesitter').update():wait(300000)
end)
