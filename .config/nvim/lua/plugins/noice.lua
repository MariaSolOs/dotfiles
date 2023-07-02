-- Nicer notications and command line UI.
return {
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
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
                signature = {
                    auto_open = {
                        enabled = false,
                    },
                },
                message = {
                    view = 'mini',
                },
            },
            messages = {
                view = 'mini',
                view_warn = 'mini',
            },
            routes = {
                -- Send all the messages about "X not available" to the mini view.
                {
                    filter = {
                        event = 'notify',
                        find = 'available',
                    },
                    view = 'mini',
                },
            },
        },
        dependencies = {
            'MunifTanjim/nui.nvim',
            'rcarriga/nvim-notify',
        },
        keys = {
            { '<leader>tn', ':NoiceTelescope<cr>', desc = 'Noice' },
            {
                '<C-f>',
                function()
                    if not require('noice.lsp').scroll(4) then
                        return '<C-f>'
                    end
                end,
                silent = true,
                expr = true,
                desc = 'Scroll forward',
                mode = { 'i', 'n', 's' },
            },
            {
                '<C-b>',
                function()
                    if not require('noice.lsp').scroll(-4) then
                        return '<C-b>'
                    end
                end,
                silent = true,
                expr = true,
                desc = 'Scroll backward',
                mode = { 'i', 'n', 's' },
            },
        },
    },
}
