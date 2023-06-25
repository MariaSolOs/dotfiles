-- Copilot.
return {
    {
        'zbirenbaum/copilot.lua',
        cmd = 'Copilot',
        event = 'InsertEnter',
        dependencies = 'hrsh7th/nvim-cmp',
        opts = {
            -- I don't find the panel useful.
            panel = {
                enabled = false,
            },
            suggestion = {
                auto_trigger = true,
                -- Use alt to interact with Copilot.
                keymap = {
                    -- Disable the built-in mapping, we'll configure it in nvim-cmp.
                    accept = false,
                    accept_word = '<M-w>',
                    accept_line = '<M-l>',
                    next = '<M-]>',
                    prev = '<M-[>',
                    -- Disable this mapping since I enable it only if a suggestion is visible.
                    dismiss = false,
                },
            },
            filetypes = {
                markdown = true,
            },
        },
        config = function(_, opts)
            local cmp = require 'cmp'
            local copilot = require 'copilot.suggestion'

            require('copilot').setup(opts)

            -- Hide suggestions when the completion menu is open.
            cmp.event:on('menu_opened', function()
                copilot.dismiss()
                vim.b.copilot_suggestion_hidden = true
            end)
            cmp.event:on('menu_closed', function()
                vim.b.copilot_suggestion_hidden = false
            end)

            -- Always dismiss the suggestion when leaving insert mode.
            vim.api.nvim_create_autocmd('InsertLeave', {
                pattern = '*',
                callback = function()
                    if copilot.is_visible() then
                        copilot.dismiss()
                    end
                end,
            })

            -- HACK: Only enable the dismiss mapping if a suggestion is visible.
            vim.keymap.set('i', '/', function()
                if copilot.is_visible() then
                    copilot.dismiss()
                    return '<Ignore>'
                else
                    return '/'
                end
            end, { expr = true })
        end,
    },
}
