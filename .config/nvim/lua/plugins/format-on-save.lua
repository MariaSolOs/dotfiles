-- Formatting on save.
return {
    {
        'elentok/format-on-save.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            local formatters = require 'format-on-save.formatters'

            require('format-on-save').setup {
                formatter_by_ft = {
                    lua = formatters.stylua,
                },
                -- Just use LSP if there's not an assigned formatter.
                fallback_formatter = formatters.lsp,
                -- Don't show errors.
                error_notifier = {
                    show = function() end,
                    hide = function() end,
                },
            }
        end,
    },
}
