local icons = require 'icons'

-- Picker, finder, etc.
return {
    {
        'ibhagwan/fzf-lua',
        cmd = 'FzfLua',
        keys = {
            { '<leader>f<', '<cmd>FzfLua resume<cr>', desc = 'Resume last command' },
            {
                '<leader>fb',
                function()
                    require('fzf-lua').lgrep_curbuf {
                        winopts = {
                            height = 0.6,
                            width = 0.5,
                            preview = { vertical = 'up:70%' },
                        },
                    }
                end,
                desc = 'Grep current buffer',
            },
            { '<leader>fc', '<cmd>FzfLua highlights<cr>', desc = 'Highlights' },
            { '<leader>fd', '<cmd>FzfLua lsp_document_diagnostics<cr>', desc = 'Document diagnostics' },
            { '<leader>fD', '<cmd>FzfLua lsp_workspace_diagnostics<cr>', desc = 'Workspace diagnostics' },
            { '<leader>ff', '<cmd>FzfLua files<cr>', desc = 'Find files' },
            { '<leader>fg', '<cmd>FzfLua live_grep_glob<cr>', desc = 'Grep' },
            { '<leader>fg', '<cmd>FzfLua grep_visual<cr>', desc = 'Grep', mode = 'x' },
            { '<leader>fh', '<cmd>FzfLua help_tags<cr>', desc = 'Help' },
            {
                '<leader>fr',
                function()
                    -- Read from ShaDa to include files that were already deleted from the buffer list.
                    vim.cmd 'rshada!'
                    require('fzf-lua').oldfiles()
                end,
                desc = 'Recently opened files',
            },
            { 'z=', '<cmd>FzfLua spell_suggest<cr>', desc = 'Spelling suggestions' },
        },
        opts = function()
            local actions = require 'fzf-lua.actions'

            return {
                -- Make stuff better combine with the editor.
                fzf_colors = {
                    bg = { 'bg', 'Normal' },
                    gutter = { 'bg', 'Normal' },
                    info = { 'fg', 'Conditional' },
                    scrollbar = { 'bg', 'Normal' },
                    separator = { 'fg', 'Comment' },
                },
                fzf_opts = {
                    ['--info'] = 'default',
                    ['--layout'] = 'reverse-list',
                },
                keymap = {
                    builtin = {
                        ['<C-/>'] = 'toggle-help',
                        ['<C-a>'] = 'toggle-fullscreen',
                        ['<C-i>'] = 'toggle-preview',
                        ['<C-f>'] = 'preview-page-down',
                        ['<C-b>'] = 'preview-page-up',
                    },
                    fzf = {
                        ['alt-s'] = 'toggle',
                        ['alt-a'] = 'toggle-all',
                    },
                },
                winopts = {
                    height = 0.7,
                    width = 0.55,
                    title_flags = false,
                    preview = {
                        scrollbar = false,
                        layout = 'vertical',
                        vertical = 'up:40%',
                    },
                },
                defaults = { git_icons = false },
                -- Configuration for specific commands.
                files = {
                    winopts = {
                        preview = { hidden = true },
                    },
                },
                grep = {
                    header_prefix = icons.misc.search .. ' ',
                },
                helptags = {
                    actions = {
                        -- Open help pages in a vertical split.
                        ['enter'] = actions.help_vert,
                    },
                },
                lsp = {
                    symbols = {
                        symbol_icons = icons.symbol_kinds,
                    },
                },
                oldfiles = {
                    include_current_session = true,
                    winopts = {
                        preview = { hidden = true },
                    },
                },
            }
        end,
    },
}
