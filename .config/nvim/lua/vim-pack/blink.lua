local add_on_event = require('vim-pack').add_on_event
local on_plugin_update = require('vim-pack').on_plugin_update

-- Auto-completion and snippets:
add_on_event('InsertEnter', {
    {
        src = 'L3MON4D3/LuaSnip',
    },
    {
        src = 'saghen/blink.cmp',
        opts = {
            keymap = {
                ['<CR>'] = { 'accept', 'fallback' },
                ['<C-\\>'] = { 'hide', 'fallback' },
                ['<C-n>'] = { 'select_next', 'show' },
                ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
                ['<C-p>'] = { 'select_prev' },
                ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
                ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
            },
            completion = {
                list = {
                    -- Insert items while navigating the completion list.
                    selection = { preselect = false, auto_insert = true },
                    max_items = 10,
                },
                documentation = { auto_show = true },
                menu = {
                    scrollbar = false,
                    draw = {
                        gap = 2,
                        columns = {
                            { 'kind_icon', 'kind', gap = 1 },
                            { 'label', 'label_description', gap = 1 },
                        },
                    },
                },
            },
            snippets = { preset = 'luasnip' },
            -- Disable command line completion:
            cmdline = { enabled = false },
            sources = {
                -- Disable some sources in comments and strings.
                default = function()
                    local sources = { 'lsp', 'buffer' }
                    local ok, node = pcall(vim.treesitter.get_node)

                    if ok and node then
                        if not vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
                            table.insert(sources, 'path')
                        end
                        if node:type() ~= 'string' then
                            table.insert(sources, 'snippets')
                        end
                    end

                    return sources
                end,
            },
            appearance = {
                kind_icons = require('icons').symbol_kinds,
            },
        },
    },
})

-- Snippets.
local snippets = {
    {
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
            ---@diagnostic enable: undefined-field
        end,
    },
}
on_plugin_update('blink.cmp', 'cargo +nightly build --release')
