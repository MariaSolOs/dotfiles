-- Completion.
return {
    {
        'L3MON4D3/LuaSnip',
        event = 'InsertEnter',
        opts = function()
            local types = require 'luasnip.util.types'

            return {
                -- Display a cursor-like placeholder in unvisited nodes
                -- of the snippet.
                ext_opts = {
                    [types.insertNode] = {
                        unvisited = {
                            virt_text = { { '|', 'Conceal' } },
                            virt_text_pos = 'inline',
                        },
                    },
                    [types.exitNode] = {
                        unvisited = {
                            virt_text = { { '|', 'Conceal' } },
                            virt_text_pos = 'inline',
                        },
                    },
                },
            }
        end,
        config = function(_, opts)
            local luasnip = require 'luasnip'

            luasnip.setup(opts)

            -- Use <C-c> to select a choice in a snippet.
            vim.keymap.set({ 'i', 's' }, '<C-c>', function()
                if luasnip.choice_active() then
                    require 'luasnip.extras.select_choice'()
                end
            end, { desc = 'Select choice' })

            vim.api.nvim_create_autocmd('ModeChanged', {
                group = vim.api.nvim_create_augroup('mariasolos/unlink_snippet', { clear = true }),
                desc = 'Cancel the snippet session when leaving the snippet region',
                callback = function(args)
                    if
                        luasnip.session
                        and luasnip.session.current_nodes[args.buf]
                        and not luasnip.expand_or_locally_jumpable()
                    then
                        luasnip.unlink_current()
                    end
                end,
            })
        end,
    },
}
