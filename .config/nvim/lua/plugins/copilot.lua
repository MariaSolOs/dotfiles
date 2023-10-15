-- Copilot.
return {
    {
        'zbirenbaum/copilot.lua',
        event = 'InsertEnter',
        opts = {
            -- I don't find the panel useful.
            panel = { enabled = false },
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
                    dismiss = '/',
                },
            },
            filetypes = { markdown = true },
        },
        config = function(_, opts)
            local cmp = require 'cmp'
            local copilot = require 'copilot.suggestion'
            local luasnip = require 'luasnip'

            require('copilot').setup(opts)

            ---@param trigger boolean
            local function set_trigger(trigger)
                if not trigger and copilot.is_visible() then
                    copilot.dismiss()
                end
                vim.b.copilot_suggestion_auto_trigger = trigger
                vim.b.copilot_suggestion_hidden = not trigger
            end

            -- Hide suggestions when the completion menu is open.
            cmp.event:on('menu_opened', function()
                set_trigger(false)
            end)
            cmp.event:on('menu_closed', function()
                set_trigger(not luasnip.expand_or_locally_jumpable())
            end)

            vim.api.nvim_create_autocmd('User', {
                desc = 'Disable Copilot inside snippets',
                pattern = { 'LuasnipInsertNodeEnter', 'LuasnipInsertNodeLeave' },
                callback = function()
                    set_trigger(not luasnip.expand_or_locally_jumpable())
                end,
            })
        end,
    },
}
