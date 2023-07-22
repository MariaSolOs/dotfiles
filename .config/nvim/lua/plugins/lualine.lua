-- Statusline.
return {
    {
        'nvim-lualine/lualine.nvim',
        event = 'VeryLazy',
        opts = {
            options = {
                theme = 'dracula-nvim',
                component_separators = '|',
                section_separators = '',
            },
            sections = {
                lualine_b = { 'branch', 'diff' },
                lualine_c = {
                    -- Show LSP progress.
                    {
                        function()
                            return require('noice').api.status.lsp_progress.get_hl()
                        end,
                        cond = function()
                            return package.loaded['noice'] and require('noice').api.status.lsp_progress.has()
                        end,
                    },
                    -- Show macro recording messages.
                    {
                        function()
                            return require('noice').api.status.mode.get()
                        end,
                        cond = function()
                            return package.loaded['noice'] and require('noice').api.status.mode.has()
                        end,
                    },
                },
                lualine_x = {
                    {
                        'diagnostics',
                        sections = { 'error', 'warn', 'info', 'hint' },
                    },
                },
                lualine_y = { 'encoding', 'filetype' },
            },
        },
        config = function(_, opts)
            require('lualine').setup(opts)

            -- Disable this since the mode will be displayed by lualine.
            vim.o.showmode = false

            -- Update the statusline with the latest LSP message.
            vim.api.nvim_create_autocmd('LspProgress', {
                pattern = '*',
                command = 'redrawstatus',
            })
        end,
    },
}
