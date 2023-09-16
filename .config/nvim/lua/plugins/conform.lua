-- Formatting.
return {
    {
        'stevearc/conform.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
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
                    lsp_fallback = vim.iter({ 'json', 'jsonc', 'rust' }):find(vim.bo[bufnr].filetype) ~= nil,
                }
            end,
        },
        config = function(_, opts)
            require('conform').setup(opts)

            -- Add commands to toggle formatting.
            vim.api.nvim_create_user_command('FormatDisable', function()
                vim.g.disable_autoformat = true
            end, { desc = 'Disable format on save' })
            vim.api.nvim_create_user_command('FormatEnable', function()
                vim.g.disable_autoformat = false
            end, { desc = 'Enable format on save' })
        end,
    },
}
