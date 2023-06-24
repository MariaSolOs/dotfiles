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
                            -- HACK: Just show the mode if we're recording.
                            local mode = require('noice').api.status.mode.get()
                            return string.match(mode, '^recording @.*') or ''
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
