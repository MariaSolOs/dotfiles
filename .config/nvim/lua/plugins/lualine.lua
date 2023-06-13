-- Statusline.
return {
    {
        'nvim-lualine/lualine.nvim',
        event = 'VeryLazy',
        opts = {
            options = {
                icons_enabled = false,
                theme = 'catppuccin',
                component_separators = '|',
                section_separators = '',
            },
            sections = {
                lualine_b = {
                    'branch',
                    'diff',
                },
                lualine_x = {
                    {
                        'diagnostics',
                        icons_enabled = true,
                        sections = { 'error', 'warn', 'info', 'hint' },
                    }
                },
                lualine_y = { 'encoding', 'filetype' }
            }
        },
    }
}
