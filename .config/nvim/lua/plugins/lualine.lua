-- Statusline.
return {
    {
        'nvim-lualine/lualine.nvim',
        event = 'VeryLazy',
        opts = {
            options = {
                theme = 'miss-dracula',
                component_separators = '|',
                section_separators = '',
            },
            sections = {
                lualine_b = {
                    'branch',
                    'diff',
                },
                lualine_c = {
                    {
                        function()
                            local mode = require('noice').api.status.mode.get()

                            -- Don't show --INSERT-- since there's already a section showing the mode.
                            if string.match(mode, 'INSERT') then
                                return ''
                            else
                                return mode
                            end
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
    },
}
