-- Nice notifications, command line UI, and more.
-- NOTE: Highlights are broken rn, but https://github.com/folke/noice.nvim/pull/571 fixes it.
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
            {
                '<S-Enter>',
                function()
                    require('noice').redirect(vim.fn.getcmdline())
                end,
                desc = 'Redirect command',
                mode = 'c',
            },
        },
        opts = function()
            local cmdline_formats = require('noice.config').defaults().cmdline.format
            for _, format in pairs(cmdline_formats) do
                -- TODO: Set this to false when https://github.com/folke/noice.nvim/pull/558 gets merged.
                format.conceal = true
            end

            return {
                presets = {
                    -- Have borders around hover and signature help.
                    lsp_doc_border = true,
                    command_palette = true,
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
                -- Send redirected messages to the messages view.
                redirect = { view = 'messages' },
                routes = {
                    -- Redirect long messages to the split view, except for
                    -- confirmation messages from minifiles.
                    {
                        filter = {
                            event = 'msg_show',
                            min_height = 20,
                            cond = function()
                                local bufr = vim.api.nvim_get_current_buf()
                                return vim.bo[bufr].filetype ~= 'minifiles'
                            end,
                        },
                        view = 'cmdline_output',
                    },
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
                                { find = '%d lines filtered' },
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
                    -- Ignore debug messages from indent-blankline.
                    {
                        filter = {
                            event = 'notify',
                            kind = 'debug',
                            find = 'indent%-blankline',
                        },
                        opts = { skip = true },
                    },
                    -- Ignore fzf's message when previewing huge files.
                    {
                        filter = {
                            event = 'msg_show',
                            find = "consider increasing 'syntax_limit_b",
                        },
                        opts = { skip = true },
                    },
                },
                cmdline = {
                    -- Use the default formats, but don't conceal the prefixes.
                    format = cmdline_formats,
                },
                format = {
                    -- Looks better for Lualine.
                    progress = { align = 'left' },
                },
                views = {
                    cmdline_popup = {
                        position = { row = 12 },
                    },
                    cmdline_popupmenu = {
                        position = { row = 15 },
                    },
                    mini = {
                        -- Hide mini messages after 5 seconds.
                        timeout = 5000,
                    },
                },
            }
        end,
    },
}
