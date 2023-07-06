-- Start dashboard.
return {
    {
        'goolord/alpha-nvim',
        event = 'VimEnter',
        dependencies = 'nvim-tree/nvim-web-devicons',
        opts = function()
            local dashboard = require 'alpha.themes.dashboard'

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

            local dashboard_button = function(sc, txt, keybind)
                local button = dashboard.button(sc, txt, keybind)
                button.opts.hl_shortcut = 'AlphaShortcut'
                button.opts.hl = 'AlphaButtons'
                return button
            end
            dashboard.section.buttons.val = {
                dashboard_button('f', '  Find file', ':Telescope find_files<cr>'),
                dashboard_button('r', '  Recent files', ':Telescope oldfiles<cr>'),
                dashboard_button('c', '  Config', ':e $MYVIMRC | :cd %:p:h<cr>'),
                dashboard_button('q', '  Quit', ':qa<cr>'),
                { type = 'padding', val = 2 },
            }
            dashboard.section.buttons.opts.hl = 'AlphaButtons'
            dashboard.opts.layout[1].val = #dashboard.section.buttons.val

            dashboard.section.footer.val = "It's not a bug, it's a feature. 🌟"
            dashboard.section.footer.opts.hl = 'AlphaFooter'

            return dashboard
        end,
        config = function(_, dashboard)
            require('alpha').setup(dashboard.opts)
        end,
    },
}
