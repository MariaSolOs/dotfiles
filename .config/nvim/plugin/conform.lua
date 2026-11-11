local add_on_event = require('vim-pack').add_on_event

add_on_event('BufWritePre', {
    {
        src = 'stevearc/conform.nvim',
        opts = {
            -- Leave me alone.
            notify_on_error = false,
            notify_no_formatters = false,
            formatters_by_ft = {
                c = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
                go = { name = 'gopls', timeout_ms = 500, lsp_format = 'prefer' },
                java = { 'palantir-java-format' },
                javascript = { 'oxfmt', 'prettier', stop_after_first = true, name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                javascriptreact = { 'oxfmt', 'prettier', stop_after_first = true, name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                json = { 'oxfmt', 'prettier', stop_after_first = true, name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                jsonc = { 'oxfmt', 'prettier', stop_after_first = true, name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                less = { 'oxfmt', 'prettier', stop_after_first = true },
                lua = { 'stylua' },
                markdown = { 'oxfmt', 'prettier', stop_after_first = true, name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                python = { 'ruff_format' },
                rust = { name = 'rust_analyzer', timeout_ms = 500, lsp_format = 'prefer' },
                scss = { 'oxfmt', 'prettier', stop_after_first = true },
                sh = { 'shfmt' },
                typescript = { 'oxfmt', 'prettier', stop_after_first = true, name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                typescriptreact = { 'oxfmt', 'prettier', stop_after_first = true, name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                yaml = { 'oxfmt', 'prettier', stop_after_first = true },
                -- For filetypes without a formatter:
                ['_'] = { 'trim_whitespace', 'trim_newlines' },
            },
            format_on_save = function()
                if vim.bo.filetype == 'java' then
                    -- Java formatting is too slow to do on save.
                    return nil
                end

                -- Don't format when minifiles is open, since that triggers the "confirm without
                -- synchronization" message.
                if vim.g.minifiles_active then
                    return nil
                end

                -- Skip formatting if triggered from my special save command.
                if vim.g.skip_formatting then
                    vim.g.skip_formatting = false
                    return nil
                end

                -- Stop if we disabled auto-formatting.
                if not vim.g.autoformat then
                    return nil
                end

                return {}
            end,
            formatters = {
                -- Require configuration files.
                prettier = { require_cwd = true },
                -- Same for oxfmt.
                oxfmt = { require_cwd = true },
            },
        },
    },
})

-- Use conform for gq.
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

-- Start auto-formatting by default (and disable with my ToggleFormat command).
vim.g.autoformat = true
