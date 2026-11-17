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
                graphql = { 'prettier' },
                java = { 'palantir-java-format' },
                javascript = { 'oxfmt', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                javascriptreact = { 'oxfmt', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                json = { 'oxfmt', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                jsonc = { 'oxfmt', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                less = { 'oxfmt' },
                lua = { 'stylua' },
                markdown = { 'oxfmt', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                python = { 'ruff_format' },
                rust = { name = 'rust_analyzer', timeout_ms = 500, lsp_format = 'prefer' },
                scss = { 'oxfmt' },
                sh = { 'shfmt' },
                typescript = { 'oxfmt', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                typescriptreact = { 'oxfmt', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
                yaml = { 'oxfmt' },
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
                prettier = { require_cwd = true },
                oxfmt = {
                    require_cwd = true,
                    -- TODO: Remove this override https://github.com/stevearc/conform.nvim/pull/910 is merged.
                    cwd = function(self, ctx)
                        return require('conform.util').root_file {
                            '.oxfmtrc.json',
                            '.oxfmtrc.jsonc',
                            'oxfmt.config.ts',
                            'oxfmt.config.mts',
                        }(self, ctx)
                    end,
                },
            },
        },
    },
})

-- Use conform for gq.
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

-- Start auto-formatting by default (and disable with my ToggleFormat command).
vim.g.autoformat = true
