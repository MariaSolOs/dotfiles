-- Nicer notications and command line UI.
return {
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        opts = {
            presets = {
                -- Have borders around hover and signature help.
                lsp_doc_border = true,
            },
            lsp = {
                override = {
                    ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                    ['vim.lsp.util.stylize_markdown'] = true,
                    ['cmp.entry.get_documentation'] = true,
                },
            },
            -- Use a simple UI for these.
            messages = { view = 'mini' },
            routes = {
                {
                    filter = {
                        event = 'lsp',
                        kind = 'progress',
                        any = {
                            -- Just show the final progress notifications.
                            { find = '(%d%%)' },
                            {
                                cond = function(message)
                                    -- Don't show progress from the null-ls client.
                                    local client = vim.tbl_get(message.opts, 'progress', 'client')
                                    return client == 'null-ls'
                                end,
                            },
                        },
                    },
                    opts = { skip = true },
                },
                {
                    -- Don't show written messages.
                    filter = {
                        event = 'msg_show',
                        kind = '',
                    },
                    opts = { skip = true },
                },
                {
                    -- Don't show Neo-tree's info notications.
                    filter = {
                        event = 'notify',
                        find = 'Neo-tree INFO',
                        cond = function(message)
                            -- TODO: Filter out these.
                            return true
                        end,
                    },
                    opts = { skip = true },
                },
            },
            -- Show a popup menu for completions when using the command line.
            views = {
                cmdline_popup = {
                    position = {
                        row = 5,
                        col = '50%',
                    },
                    size = {
                        width = 60,
                        height = 'auto',
                    },
                },
                popupmenu = {
                    relative = 'editor',
                    position = {
                        row = 8,
                        col = '50%',
                    },
                    size = {
                        width = 60,
                        height = 10,
                    },
                    border = {
                        style = 'rounded',
                        padding = { 0, 1 },
                    },
                    win_options = {
                        winhighlight = { Normal = 'Normal', FloatBorder = 'DiagnosticInfo' },
                    },
                },
            },
        },
        dependencies = {
            'MunifTanjim/nui.nvim',
            'rcarriga/nvim-notify',
        },
        keys = {
            { '<leader>sn', ':NoiceTelescope<cr>', desc = 'Search Noice' },
        },
        init = function()
            -- LSP hover doc scrolling.
            vim.keymap.set({ 'n', 'i', 's' }, '<C-f>', function()
                if not require('noice.lsp').scroll(4) then
                    return '<C-f>'
                end
            end, { silent = true, expr = true })

            vim.keymap.set({ 'n', 'i', 's' }, '<C-b>', function()
                if not require('noice.lsp').scroll(-4) then
                    return '<C-b>'
                end
            end, { silent = true, expr = true })
        end,
    },
}
