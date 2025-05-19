local icons = require 'icons'

-- Picker, finder, etc.
return {
    {
        'ibhagwan/fzf-lua',
        cmd = 'FzfLua',
        keys = {
            { '<leader>f<', '<cmd>FzfLua resume<cr>', desc = 'Resume last fzf command' },
            {
                '<leader>fb',
                function()
                    require('fzf-lua').blines {
                        winopts = {
                            height = 0.6,
                            width = 0.5,
                            preview = { vertical = 'up:70%' },
                            -- Disable Treesitter highlighting for the matches.
                            treesitter = {
                                enabled = false,
                                fzf_colors = { ['fg'] = { 'fg', 'CursorLine' }, ['bg'] = { 'bg', 'Normal' } },
                            },
                        },
                        fzf_opts = {
                            ['--layout'] = 'reverse',
                        },
                    }
                end,
                desc = 'Buffer lines',
                mode = { 'n', 'x' },
            },
            { '<leader>fc', '<cmd>FzfLua highlights<cr>', desc = 'Highlights' },
            { '<leader>fd', '<cmd>FzfLua lsp_document_diagnostics<cr>', desc = 'Document diagnostics' },
            { '<leader>fD', '<cmd>FzfLua lsp_workspace_diagnostics<cr>', desc = 'Workspace diagnostics' },
            { '<leader>ff', '<cmd>FzfLua files<cr>', desc = 'Find files' },
            { '<leader>fg', '<cmd>FzfLua live_grep<cr>', desc = 'Grep' },
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
                { 'border-fused', 'hide' },
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
                        ['ctrl-i'] = 'toggle-preview',
                    },
                },
                winopts = {
                    height = 0.7,
                    width = 0.55,
                    preview = {
                        scrollbar = false,
                        layout = 'vertical',
                        vertical = 'up:40%',
                    },
                },
                defaults = { git_icons = false },
                previewers = {
                    codeaction = { toggle_behavior = 'extend' },
                },
                -- Configuration for specific commands.
                files = {
                    winopts = {
                        preview = { hidden = true },
                    },
                },
                grep = {
                    header_prefix = icons.misc.search .. ' ',
                    rg_glob_fn = function(query, opts)
                        local regex, flags = query:match(string.format('^(.*)%s(.*)$', opts.glob_separator))
                        -- Return the original query if there's no separator.
                        return (regex or query), flags
                    end,
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
                    code_actions = {
                        winopts = {
                            width = 70,
                            height = 20,
                            relative = 'cursor',
                            preview = {
                                hidden = true,
                                vertical = 'down:50%',
                            },
                        },
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
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.select = function(items, opts, on_choice)
                local ui_select = require 'fzf-lua.providers.ui_select'

                -- Register the fzf-lua picker the first time we call select.
                if not ui_select.is_registered() then
                    ui_select.register(function(ui_opts)
                        if ui_opts.kind == 'luasnip' then
                            ui_opts.prompt = 'Snippet choice: '
                            ui_opts.winopts = {
                                relative = 'cursor',
                                height = 0.35,
                                width = 0.3,
                            }
                        else
                            ui_opts.winopts = { height = 0.5, width = 0.4 }
                        end

                        -- Use the kind (if available) to set the previewer's title.
                        if ui_opts.kind then
                            ui_opts.winopts.title = string.format(' %s ', ui_opts.kind)
                        end

                        return ui_opts
                    end)
                end

                -- Don't show the picker if there's nothing to pick.
                if #items > 0 then
                    return vim.ui.select(items, opts, on_choice)
                end
            end
        end,
    },
}
