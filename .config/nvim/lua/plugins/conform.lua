-- Formatting.
return {
    {
        'stevearc/conform.nvim',
        event = { 'LspAttach', 'BufWritePre' },
        opts = {
            notify_on_error = false,
            formatters_by_ft = {
                lua = { 'stylua' },
                python = { 'black' },
                sh = { 'shfmt' },
            },
            format_on_save = function(bufnr)
                if not vim.b[bufnr].format_on_save then
                    return
                end

                local res = { timeout_ms = 500 }
                local filetype = vim.bo[bufnr].filetype

                -- Only format JavaScript if dprint is available.
                if filetype == 'javascript' and require('conform').get_formatter_info('dprint', bufnr).available then
                    res.lsp_fallback = true
                else
                    res.lsp_fallback = vim.tbl_contains({ 'c', 'json', 'jsonc', 'rust' }, filetype)
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
