-- Nice notifications, command line UI, and more.
return {
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        dependencies = 'MunifTanjim/nui.nvim',
        opts = {
            presets = {
                -- Have borders around hover and signature help.
                lsp_doc_border = true,
                command_palette = true,
                long_message_to_split = true,
            },
            lsp = {
                override = {
                    ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                    ['vim.lsp.util.stylize_markdown'] = true,
                    ['cmp.entry.get_documentation'] = true,
                },
                -- I use a keymap for opening this when needed.
                signature = {
                    auto_open = { enabled = false },
                },
            },
            status = {
                -- Statusline component for LSP progress notifications.
                lsp_progress = { event = 'lsp', kind = 'progress' },
            },
            routes = {
                -- Ignore the typical vim change messages.
                {
                    filter = {
                        event = 'msg_show',
                        any = {
                            { find = '%d+L, %d+B' },
                            { find = '; after #%d+' },
                            { find = '; before #%d+' },
                            { find = '%d fewer lines' },
                            { find = '%d more lines' },
                        },
                    },
                    opts = { skip = true },
                },
                -- Don't show these in the default view, use Lualine instead.
                {
                    filter = {
                        event = 'lsp',
                        kind = 'progress',
                    },
                    opts = { skip = true },
                },
            },
        },
        keys = {
            { '<leader>tn', '<cmd>NoiceTelescope<cr>', desc = 'Noice' },
            {
                '<C-f>',
                function()
                    if not require('noice.lsp').scroll(4) then
                        return '<C-f>'
                    end
                end,
                expr = true,
                mode = { 'i', 'n', 's' },
            },
            {
                '<C-b>',
                function()
                    if not require('noice.lsp').scroll(-4) then
                        return '<C-b>'
                    end
                end,
                expr = true,
                mode = { 'i', 'n', 's' },
            },
        },
    },
}
