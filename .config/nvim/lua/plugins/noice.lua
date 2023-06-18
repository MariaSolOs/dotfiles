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
            },
            -- Send non-error/warnings to the mini view.
            messages = { view = 'mini' },
            routes = {
                -- Don't show Neo-tree's info notications.
                {
                    filter = {
                        event = 'notify',
                        kind = 'info',
                        cond = function(message)
                            if message.event == 'notify' and message.kind == 'info' then
                                return message:content():find '[Neo-tree INFO]'
                            end
                            return false
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

            -- Highlights for the progress bar.
            vim.api.nvim_set_hl(0, 'NoiceFormatProgressDone', { bg = '#27E1C1', fg = '#000000' })
            vim.api.nvim_set_hl(0, 'NoiceLspProgressSpinner', { fg = '#27E1C1' })
            vim.api.nvim_set_hl(0, 'NoiceFormatProgressTodo', { link = 'NonText' })
        end,
    },
}
