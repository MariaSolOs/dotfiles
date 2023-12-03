-- Start dashboard.
return {
    {
        'goolord/alpha-nvim',
        event = 'VimEnter',
        opts = function()
            local dashboard = require 'alpha.themes.dashboard'
            local icons = require 'icons'

            -- Add some extra padding at the top.
            dashboard.opts.layout[1].val = 5

            local header = [[
                ███╗   ██╗ ██████╗ ████████╗     █████╗     ██████╗ ██╗   ██╗ ██████╗
                ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔══██╗    ██╔══██╗██║   ██║██╔════╝
                ██╔██╗ ██║██║   ██║   ██║       ███████║    ██████╔╝██║   ██║██║  ███╗
                ██║╚██╗██║██║   ██║   ██║       ██╔══██║    ██╔══██╗██║   ██║██║   ██║
                ██║ ╚████║╚██████╔╝   ██║       ██║  ██║    ██████╔╝╚██████╔╝╚██████╔╝▄█╗
                ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚═╝  ╚═╝    ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝

██████╗ ██╗   ██╗████████╗     █████╗     ███████╗███████╗ █████╗ ████████╗██╗   ██╗██████╗ ███████╗
██╔══██╗██║   ██║╚══██╔══╝    ██╔══██╗    ██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔════╝
██████╔╝██║   ██║   ██║       ███████║    █████╗  █████╗  ███████║   ██║   ██║   ██║██████╔╝█████╗
██╔══██╗██║   ██║   ██║       ██╔══██║    ██╔══╝  ██╔══╝  ██╔══██║   ██║   ██║   ██║██╔══██╗██╔══╝
██████╔╝╚██████╔╝   ██║       ██║  ██║    ██║     ███████╗██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗██╗
╚═════╝  ╚═════╝    ╚═╝       ╚═╝  ╚═╝    ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝
            ]]
            dashboard.section.header.val = vim.split(header, '\n')
            dashboard.section.header.opts.hl = 'AlphaHeader'

            local function dashboard_button(sc, txt, keybind)
                local button = dashboard.button(sc, txt, keybind)
                button.opts.hl_shortcut = 'AlphaShortcut'
                button.opts.hl = 'AlphaButtons'
                -- Do not move the cursor, it creates a weird effect at the beginning.
                button.opts.cursor = 0
                return button
            end
            dashboard.section.buttons.val = {
                dashboard_button('f', icons.symbol_kinds.Folder .. '  Find file', '<cmd>FzfLua files<cr>'),
                dashboard_button('r', '  Recent files', '<cmd>FzfLua oldfiles<cr>'),
                dashboard_button('g', icons.misc.search .. '  Grep', '<cmd>FzfLua live_grep_glob<cr>'),
                dashboard_button('q', '  Quit', '<cmd>qa<cr>'),
                { type = 'padding', val = 2 },
            }
            dashboard.section.buttons.opts.hl = 'AlphaButtons'

            return dashboard.opts
        end,
        config = function(_, opts)
            require('alpha').setup(opts)

            -- Hide some parts of the UI while the dashboard is open.
            local alpha_group = vim.api.nvim_create_augroup('mariasolos/alpha', { clear = true })
            vim.api.nvim_create_autocmd('User', {
                group = alpha_group,
                desc = 'Minimal UI in Alpha dashboard',
                pattern = 'AlphaReady',
                once = true,
                callback = function(args)
                    vim.o.laststatus = 0
                    vim.o.cmdheight = 0

                    vim.api.nvim_create_autocmd('BufUnload', {
                        group = alpha_group,
                        buffer = args.buf,
                        once = true,
                        callback = function()
                            vim.o.laststatus = 3
                            vim.o.cmdheight = 1
                        end,
                    })
                end,
            })
        end,
    },
}
