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
                -- Don't format when minifiles is open, since that triggers the "confirm without
                -- synchronization" message.
                if vim.g.minifiles_active then
                    return
                end

                if not vim.b[bufnr].format_on_save then
                    return
                end

                local res = { timeout_ms = 500 }
                local filetype = vim.bo[bufnr].filetype

                -- Only format JS/TS if dprint is available.
                if
                    vim.tbl_contains({ 'typescript', 'javascript' }, filetype)
                    and require('conform').get_formatter_info('dprint', bufnr).available
                then
                    res.lsp_format = 'fallback'
                else
                    res.lsp_format = vim.tbl_contains({ 'c', 'json', 'jsonc', 'rust' }, filetype) and 'fallback' or nil
                end

                return res
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
