-- Formatting.
return {
    {
        'stevearc/conform.nvim',
        event = { 'LspAttach', 'BufWritePre' },
        opts = {
            notify_on_error = false,
            formatters_by_ft = {
                lua = { 'stylua' },
                sh = { 'shfmt' },
            },
            format_on_save = function(bufnr)
                if vim.b[bufnr].format_on_save then
                    return {
                        timeout_ms = 500,
                        -- Filetypes to use LSP formatting for.
                        lsp_fallback = vim.tbl_contains({ 'c', 'json', 'jsonc', 'rust' }, vim.bo[bufnr].filetype),
                    }
                end
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
                    vim.b[args.buf].format_on_save = vim.iter({ vim.fn.stdpath 'config', vim.g.personal_projects_dir })
                        :any(function(folder)
                            return vim.startswith(path, vim.fs.normalize(folder))
                        end)
                end,
            })
        end,
    },
}
