-- Nice hovers.
return {
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        dependencies = 'MunifTanjim/nui.nvim',
        keys = {
            {
                '<C-f>',
                function()
                    if not require('noice.lsp').scroll(4) then
                        return '<C-f>'
                    end
                end,
                desc = 'Scroll forward',
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
                desc = 'Scroll backward',
                expr = true,
                mode = { 'i', 'n', 's' },
            },
        },
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
                -- I use a keymap for opening this when needed.
                signature = {
                    auto_open = { enabled = false },
                },
                -- Disable progress messages.
                progress = { enabled = false },
            },
            -- Disable the message features.
            cmdline = { enabled = false },
            messages = { enabled = false },
            notify = { enabled = false },
        },
    },
}
