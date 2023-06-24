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
            routes = {
                -- This guy is way too noisy. Ignore it.
                {
                    filter = {
                        event = 'lsp',
                        kind = 'progress',
                        cond = function(message)
                            local client = vim.tbl_get(message.opts, 'progress', 'client')
                            return client == 'null-ls'
                        end,
                    },
                    opts = { skip = true },
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
            -- Hover doc scrolling.
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
