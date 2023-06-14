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
                lualine_b = {
                    'branch',
                    'diff',
                },
                lualine_x = {
                    {
                        'diagnostics',
                        sections = { 'error', 'warn', 'info', 'hint' },
                    }
                },
                lualine_y = { 'encoding', 'filetype' }
            }
        },
    }
}
