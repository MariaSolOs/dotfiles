-- Nice notifications, command line UI, and more.
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
            -- Use the default command line formats, but don't conceal the prefixes.
            local cmdline_formats = require('noice.config').defaults().cmdline.format
            for _, format in pairs(cmdline_formats) do
                format.conceal = false
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
                    -- Disable progress messages.
                    progress = { enabled = false },
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
                                return vim.bo.filetype ~= 'minifiles'
                            end,
                        },
                        view = 'cmdline_output',
                    },
                    -- Messages I don't care about.
                    {
                        filter = {
                            event = 'msg_show',
                            any = {
                                -- Typical vim change messages.
                                { find = '%d+L, %d+B' },
                                { find = '; after #%d+' },
                                { find = '; before #%d+' },
                                { find = '%d fewer lines' },
                                { find = '%d more lines' },
                                { find = '%d lines filtered' },
                                -- fzf's message when previewing huge files.
                                { find = "consider increasing 'syntax_limit_b" },
                                -- Trying to fold stuff.
                                { find = 'E%d+: No fold found' },
                            },
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
                },
                cmdline = {
                    format = cmdline_formats,
                },
                views = {
                    cmdline_popup = {
                        position = { row = 12 },
                    },
                    cmdline_popupmenu = {
                        position = { row = 15 },
                    },
                    mini = {
                        -- Hide mini messages after 4 seconds.
                        timeout = 4000,
                        -- Make a nice pink box for these.
                        position = { row = -2 },
                        border = { style = 'rounded' },
                        win_options = {
                            winhighlight = 'FloatBorder:NoiceMini,Normal:NoiceMini',
                        },
                    },
                },
            }
        end,
    },
}
