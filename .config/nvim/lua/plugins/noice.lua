-- TODO: Make signature help triggerable.
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
                },
            },
            -- Send non-error/warnings to the mini view.
            messages = { view = 'mini' },
        },
        dependencies = {
            'MunifTanjim/nui.nvim',
            'rcarriga/nvim-notify',
        },
        keys = {
            { '<leader>sn', ':NoiceTelescope<cr>', desc = 'Search Noice' },
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
