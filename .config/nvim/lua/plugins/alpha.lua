local icons = require 'icons'

-- Start dashboard.
return {
    {
        'goolord/alpha-nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
            opts = {
                -- Make the icon for query files more visible.
                override = {
                    ['scm'] = {
                        icon = '󰘧',
                        color = '#A9ABAC',
                        cterm_color = '16',
                        name = 'Scheme',
                    },
                },
            },
        },
        event = 'VimEnter',
        opts = function()
            local dashboard = require 'alpha.themes.dashboard'

            -- Add some extra padding at the top.
            dashboard.opts.layout[1].val = 7

            local header = [[
██╗  ██╗███████╗██╗   ██╗    ██████╗ ██████╗ ███████╗████████╗████████╗██╗   ██╗     ██████╗ ██╗██████╗ ██╗
██║  ██║██╔════╝╚██╗ ██╔╝    ██╔══██╗██╔══██╗██╔════╝╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝    ██╔════╝ ██║██╔══██╗██║
███████║█████╗   ╚████╔╝     ██████╔╝██████╔╝█████╗     ██║      ██║    ╚████╔╝     ██║  ███╗██║██████╔╝██║
██╔══██║██╔══╝    ╚██╔╝      ██╔═══╝ ██╔══██╗██╔══╝     ██║      ██║     ╚██╔╝      ██║   ██║██║██╔══██╗██║
██║  ██║███████╗   ██║       ██║     ██║  ██║███████╗   ██║      ██║      ██║       ╚██████╔╝██║██║  ██║███████╗
╚═╝  ╚═╝╚══════╝   ╚═╝       ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝      ╚═╝      ╚═╝        ╚═════╝ ╚═╝╚═╝  ╚═╝╚══════╝
            ]]
            dashboard.section.header.val = vim.split(header, '\n')
            dashboard.section.header.opts.hl = 'AlphaHeader'

            local function dashboard_button(sc, txt, keybind)
                local button = dashboard.button(sc, txt, keybind)
                button.opts.hl_shortcut = 'AlphaShortcut'
                button.opts.hl = 'AlphaButtons'
                return button
            end
            dashboard.section.buttons.val = {
                dashboard_button('f', icons.symbol_kinds.Folder .. '  Find file', '<cmd>FzfLua files<cr>'),
                dashboard_button('r', '  Recent files', '<cmd>FzfLua oldfiles<cr>'),
                dashboard_button('g', icons.misc.search .. '  Grep', '<cmd>FzfLua live_grep<cr>'),
                dashboard_button('q', '  Quit', '<cmd>qa<cr>'),
                { type = 'padding', val = 2 },
            }
            dashboard.section.buttons.opts.hl = 'AlphaButtons'

            dashboard.section.footer.val = "It's not a bug, it's a feature. 🌟"
            dashboard.section.footer.opts.hl = 'AlphaFooter'

            return dashboard.opts
        end,
    },
}
