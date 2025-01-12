-- Snippets.
return {
    {
        'L3MON4D3/LuaSnip',
        keys = {
            {
                '<C-r>s',
                function()
                    require('luasnip.extras.otf').on_the_fly 's'
                end,
                desc = 'Insert on-the-fly snippet',
                mode = 'i',
            },
        },
        opts = function()
            local types = require 'luasnip.util.types'
            return {
                -- Check if the current snippet was deleted.
                delete_check_events = 'TextChanged',
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
                    [types.choiceNode] = {
                        active = {
                            virt_text = { { '(snippet) choice node', 'LspInlayHint' } },
                        },
                    },
                },
            }
        end,
        config = function(_, opts)
            local luasnip = require 'luasnip'

            ---@diagnostic disable: undefined-field
            luasnip.setup(opts)

            -- Load my custom snippets:
            require('luasnip.loaders.from_vscode').lazy_load {
                paths = vim.fn.stdpath 'config' .. '/snippets',
            }

            -- Use <C-c> to select a choice in a snippet.
            vim.keymap.set({ 'i', 's' }, '<C-c>', function()
                if luasnip.choice_active() then
                    require 'luasnip.extras.select_choice'()
                end
            end, { desc = 'Select choice' })

            vim.api.nvim_create_autocmd('ModeChanged', {
                group = vim.api.nvim_create_augroup('mariasolos/unlink_snippet', { clear = true }),
                desc = 'Cancel the snippet session when leaving insert mode',
                pattern = { 's:n', 'i:*' },
                callback = function(args)
                    if
                        luasnip.session
                        and luasnip.session.current_nodes[args.buf]
                        and not luasnip.session.jump_active
                        and not luasnip.choice_active()
                    then
                        luasnip.unlink_current()
                    end
                end,
            })
            ---@diagnostic enable: undefined-field
        end,
    },
}
