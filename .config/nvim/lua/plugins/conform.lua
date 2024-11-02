-- Formatting.
-- TODO: I still don't feel like I've configured this correctly.
-- Wait to get a reply in https://github.com/stevearc/conform.nvim/issues/565.
local lang_settings = {
    c = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
    javascript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
    json = { name = 'dprint', timeout_ms = 500, lsp_format = 'prefer' },
    jsonc = { name = 'dprint', timeout_ms = 500, lsp_format = 'prefer' },
    lua = { 'stylua' },
    rust = { name = 'rust_analyzer', timeout_ms = 500, lsp_format = 'prefer' },
    sh = { 'shfmt' },
    typescript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
}
return {
    {
        'stevearc/conform.nvim',
        event = 'BufWritePre',
        opts = {
            notify_on_error = false,
            formatters_by_ft = lang_settings,
            format_on_save = function(bufnr)
                -- Don't format when minifiles is open, since that triggers the "confirm without
                -- synchronization" message.
                if vim.g.minifiles_active then
                    return
                end

                -- Stop if we haven't configured the buffer for auto-formatting.
                if not vim.b[bufnr].format_on_save then
                    return
                end

                return lang_settings[vim.bo[bufnr].ft]
            end,
        },
        init = function()
            -- Use conform for gq.
            vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

            -- Configure format on save inside my dotfiles and personal projects.
            vim.api.nvim_create_autocmd('BufEnter', {
                desc = 'Configure format on save',
                callback = function(args)
                    local path = vim.api.nvim_buf_get_name(args.buf)
                    path = vim.fs.normalize(path)
                    vim.b[args.buf].format_on_save = vim.iter({ vim.env.XDG_CONFIG_HOME, vim.g.personal_projects_dir })
                        :any(function(folder)
                            return vim.startswith(path, vim.fs.normalize(folder))
                        end)
                end,
            })
        end,
    },
}
