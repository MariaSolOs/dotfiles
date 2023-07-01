-- Copilot.
return {
    {
        'zbirenbaum/copilot.lua',
        cmd = 'Copilot',
        event = 'InsertEnter',
        opts = {
            -- I don't find the panel useful.
            panel = {
                enabled = false,
            },
            suggestion = {
                -- Use alt to interact with Copilot.
                keymap = {
                    -- Disable the built-in mapping, we'll configure it in nvim-cmp.
                    accept = false,
                    accept_word = '<M-w>',
                    accept_line = '<M-l>',
                    next = '<M-]>',
                    prev = '<M-[>',
                    dismiss = '/',
                },
            },
            filetypes = {
                markdown = true,
            },
        },
        config = function(_, opts)
            local cmp = require 'cmp'
            require('copilot').setup(opts)

            -- Hide suggestions when the completion menu is open.
            cmp.event:on('menu_opened', function()
                vim.b.copilot_suggestion_hidden = true
            end)
            cmp.event:on('menu_closed', function()
                vim.b.copilot_suggestion_hidden = false
            end)
        end,
    },
}
