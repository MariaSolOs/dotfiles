-- Auto-completion:
return {
    {
        'saghen/blink.cmp',
        build = 'cargo +nightly build --release',
        event = 'InsertEnter',
        init = function()
            -- HACK: Workaround for the non-configurable snippet navigation mappings.
            -- From https://github.com/neovim/neovim/issues/30198#issuecomment-2326075321.
            -- (And yeah this is my fault).
            local snippet_expand = vim.snippet.expand
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.snippet.expand = function(...)
                local tab_map = vim.fn.maparg('<Tab>', 'i', false, true)
                local stab_map = vim.fn.maparg('<S-Tab>', 'i', false, true)
                snippet_expand(...)
                vim.schedule(function()
                    tab_map.buffer, stab_map.buffer = 1, 1
                    vim.fn.mapset('i', false, tab_map)
                    vim.fn.mapset('i', false, stab_map)
                end)
            end
        end,
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
                menu = {
                    border = 'rounded',
                },
                documentation = {
                    auto_show = true,
                    window = { border = 'rounded' },
                },
            },
            snippets = { preset = 'default' },
            sources = {
                -- Disable command line completion:
                cmdline = {},
                -- Disable path and snippet completions inside comments and strings:
                default = function()
                    local sources = { 'lsp', 'buffer' }
                    local ok, node = pcall(vim.treesitter.get_node)

                    if
                        ok
                        and node
                        and not vim.tbl_contains({ 'string', 'comment', 'line_comment', 'block_comment' }, node:type())
                    then
                        table.insert(sources, 'snippets')
                        table.insert(sources, 'path')
                    end

                    return sources
                end,
            },
            appearance = {
                kind_icons = require('icons').symbol_kinds,
            },
        },
    },
}
