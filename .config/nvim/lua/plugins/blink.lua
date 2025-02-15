-- Auto-completion:
return {
    {
        'saghen/blink.cmp',
        dependencies = 'LuaSnip',
        build = 'cargo +nightly build --release',
        event = 'InsertEnter',
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
            snippets = { preset = 'luasnip' },
            -- Disable command line completion:
            cmdline = { enabled = false },
            sources = {
                -- Disable snippet completions inside comments and strings:
                default = function()
                    local sources = { 'lsp', 'path', 'buffer' }
                    local ok, node = pcall(vim.treesitter.get_node)

                    if
                        ok
                        and node
                        and not vim.tbl_contains({ 'string', 'comment', 'line_comment', 'block_comment' }, node:type())
                    then
                        table.insert(sources, 'snippets')
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
