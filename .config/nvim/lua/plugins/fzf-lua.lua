local icons = require 'icons'

-- Picker, finder, etc.
return {
    {
        'ibhagwan/fzf-lua',
        cmd = 'FzfLua',
        keys = {
            {
                '<leader>fb',
                function()
                    local opts = {
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

                    -- Use grep when in normal mode and blines in visual mode since the former doesn't support
                    -- searching inside visual selections.
                    -- See https://github.com/ibhagwan/fzf-lua/issues/2051
                    local mode = vim.api.nvim_get_mode().mode
                    if vim.startswith(mode, 'n') then
                        require('fzf-lua').lgrep_curbuf(opts)
                    else
                        opts.query = table.concat(vim.fn.getregion(vim.fn.getpos '.', vim.fn.getpos 'v'), '\n')
                        require('fzf-lua').blines(opts)
                    end
                end,
                desc = 'Search current buffer',
                mode = { 'n', 'x' },
            },
            { '<leader>fB', '<cmd>FzfLua buffers<cr>', desc = 'Buffers' },
            { '<leader>fc', '<cmd>FzfLua highlights<cr>', desc = 'Highlights' },
            { '<leader>fd', '<cmd>FzfLua lsp_document_diagnostics<cr>', desc = 'Document diagnostics' },
            { '<leader>ff', '<cmd>FzfLua files<cr>', desc = 'Find files' },
            { '<leader>fg', '<cmd>FzfLua live_grep<cr>', desc = 'Grep' },
            { '<leader>fg', '<cmd>FzfLua grep_visual<cr>', desc = 'Grep', mode = 'x' },
            { '<leader>fh', '<cmd>FzfLua help_tags<cr>', desc = 'Help' },
            { '<leader>fr', '<cmd>FzfLua oldfiles<cr>', desc = 'Recently opened files' },
            { '<leader>f<', '<cmd>FzfLua resume<cr>', desc = 'Resume last fzf command' },
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
                    -- Search in hidden files by default.
                    hidden = true,
                    header_prefix = icons.misc.search .. ' ',
                    rg_opts = '--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -g "!.git" -e',
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
                diagnostics = {
                    -- Remove the dashed line between diagnostic items.
                    multiline = 1,
                    diag_icons = {
                        icons.diagnostics.ERROR,
                        icons.diagnostics.WARN,
                        icons.diagnostics.INFO,
                        icons.diagnostics.HINT,
                    },
                    actions = {
                        ['ctrl-e'] = {
                            fn = function(_, opts)
                                -- If not filtering by severity, show all diagnostics.
                                if opts.severity_only then
                                    opts.severity_only = nil
                                else
                                    -- Else only show errors.
                                    opts.severity_only = vim.diagnostic.severity.ERROR
                                end
                                require('fzf-lua').resume(opts)
                            end,
                            noclose = true,
                            desc = 'toggle-all-only-errors',
                            header = function(opts)
                                return opts.severity_only and 'show all' or 'show only errors'
                            end,
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
                        elseif ui_opts.kind == 'color_presentation' then
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
