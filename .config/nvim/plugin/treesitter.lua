local add = require('vim-pack').add
local on_plugin_update = require('vim-pack').on_plugin_update

-- Prepending nvim-treesitter's `runtime/` shadows Neovim's bundled queries for every language, not just the ones
-- listed below. Those queries track nvim-treesitter's parser revisions, so any parser Neovim bundles has to be
-- reinstalled from nvim-treesitter or the two drift apart and stuff breaks.
local function install_list()
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

    local set = {}
    for _, parser in ipairs(parsers) do
        set[parser] = true
    end

    local site = vim.fn.stdpath 'data'
    for _, path in ipairs(vim.api.nvim_get_runtime_file('parser/*', true)) do
        -- Skip the parsers nvim-treesitter already installed under `site/`.
        if not vim.startswith(path, site) then
            set[vim.fn.fnamemodify(path, ':t:r')] = true
        end
    end

    return vim.tbl_keys(set)
end

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

            require('nvim-treesitter').install(install_list()):wait(300000)
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
    -- Re-install and update parsers.
    require('nvim-treesitter').install(install_list()):wait(300000)
    require('nvim-treesitter').update():wait(300000)
end)
