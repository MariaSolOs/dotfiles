local diagnostic_icons = require('icons').diagnostics

-- Statusline.
return {
    {
        'nvim-lualine/lualine.nvim',
        event = 'VeryLazy',
        opts = function()
            local colors = require 'dracula.palette-soft'

            return {
                options = {
                    theme = 'dracula-nvim',
                    component_separators = '|',
                    section_separators = '',
                    globalstatus = true,
                    disabled_filetypes = { statusline = { 'alpha' } },
                },
                sections = {
                    lualine_b = { 'branch' },
                    lualine_c = {
                        -- Show LSP progress.
                        {
                            function()
                                local lsp_progress = require('noice').api.status.lsp_progress.get_hl()
                                return vim.trim(lsp_progress)
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
                            color = { fg = colors.yellow },
                        },
                        {
                            function()
                                return '  ' .. require('dap').status()
                            end,
                            cond = function()
                                return package.loaded['dap'] and require('dap').status() ~= ''
                            end,
                            color = { fg = colors.green },
                        },
                    },
                    lualine_x = {
                        {
                            'diagnostics',
                            symbols = {
                                error = diagnostic_icons.ERROR .. ' ',
                                warn = diagnostic_icons.WARN .. ' ',
                                info = diagnostic_icons.INFO .. ' ',
                                hint = diagnostic_icons.HINT .. ' ',
                            },
                        },
                    },
                    lualine_y = { 'encoding', 'filetype' },
                },
            }
        end,
        config = function(_, opts)
            require('lualine').setup(opts)

            -- Update the statusline with the latest LSP message.
            vim.api.nvim_create_autocmd('LspProgress', { command = 'redrawstatus' })
        end,
    },
}
