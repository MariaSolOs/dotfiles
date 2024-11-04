-- Notifications.
return {
    {
        'echasnovski/mini.notify',
        lazy = true,
        opts = {
            -- These are way too noisy.
            lsp_progress = { enable = false },
            window = {
                config = {
                    border = 'rounded',
                    row = 2,
                },
                winblend = 5,
            },
        },
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.notify = function(...)
                if not package.loaded['mini.notify'] then
                    vim.notify = require('mini.notify').make_notify()
                end
                return vim.notify(...)
            end
        end,
    },
}
