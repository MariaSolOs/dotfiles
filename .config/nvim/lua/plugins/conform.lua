-- Formatting.
return {
    {
        'stevearc/conform.nvim',
        event = { 'LspAttach', 'BufWritePre' },
        opts = {
            notify_on_error = false,
            formatters_by_ft = {
                sh = { 'shfmt' },
                lua = { 'stylua' },
            },
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat then
                    return
                end

                return {
                    timeout_ms = 500,
                    -- Filetypes to use LSP formatting for.
                    lsp_fallback = vim.iter({ 'json', 'jsonc', 'rust' }):find(vim.bo[bufnr].filetype) ~= nil,
                }
            end,
        },
        init = function()
            -- Add commands to toggle formatting.
            vim.api.nvim_create_user_command('FormatDisable', function()
                vim.g.disable_autoformat = true
            end, { desc = 'Disable format on save', nargs = 0 })
            vim.api.nvim_create_user_command('FormatEnable', function()
                vim.g.disable_autoformat = false
            end, { desc = 'Enable format on save', nargs = 0 })
        end,
    },
}
