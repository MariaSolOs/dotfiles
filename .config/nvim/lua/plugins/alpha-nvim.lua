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
            dashboard.section.buttons.val = {
                dashboard.button('f', ' ' .. ' Find file', ':Telescope find_files<cr>'),
                dashboard.button('o', ' ' .. ' Recent files', ':Telescope oldfiles<cr>'),
                dashboard.button('g', ' ' .. ' Find text', ':Telescope live_grep<cr>'),
                -- Open init.lua and cd into its containing directory.
                dashboard.button('c', ' ' .. ' Config', ':e $MYVIMRC | :cd %:p:h<cr>'),
                dashboard.button('l', '󰒲 ' .. ' Lazy', ':Lazy<cr>'),
                dashboard.button('q', ' ' .. ' Quit', ':qa<cr>'),
            }
            dashboard.section.footer.val = "It's not a bug, it's a feature. 🌟"

            for _, button in ipairs(dashboard.section.buttons.val) do
                button.opts.hl = 'AlphaButtons'
                button.opts.hl_shortcut = 'AlphaShortcut'
            end
            dashboard.section.header.opts.hl = 'AlphaHeader'
            dashboard.section.buttons.opts.hl = 'AlphaButtons'
            dashboard.section.footer.opts.hl = 'AlphaFooter'
            dashboard.opts.layout[1].val = #dashboard.section.buttons.val

            return dashboard
        end,
        config = function(_, dashboard)
            require('alpha').setup(dashboard.opts)
        end,
    },
}
