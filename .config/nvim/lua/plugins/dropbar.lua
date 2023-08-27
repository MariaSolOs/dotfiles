local symbol_kinds = require('icons').symbol_kinds

-- Winbar with breadcrumbs.
return {
    {
        'Bekaboo/dropbar.nvim',
        event = 'VeryLazy',
        opts = function()
            local menu_utils = require 'dropbar.utils.menu'

            -- Closes all the windows in the current dropbar.
            local function close()
                local menu = menu_utils.get_current()
                while menu and menu.prev_menu do
                    menu = menu.prev_menu
                end
                if menu then
                    menu:close()
                end
            end

            return {
                menu = {
                    win_configs = { border = 'rounded' },
                    keymaps = {
                        -- Navigate back to the parent menu.
                        ['h'] = '<C-w>c',
                        -- Expands the entry if possible.
                        ['l'] = function()
                            local menu = menu_utils.get_current()
                            if not menu then
                                return
                            end
                            local row = vim.api.nvim_win_get_cursor(menu.win)[1]
                            local component = menu.entries[row]:first_clickable()
                            if component then
                                menu:click_on(component, nil, 1, 'l')
                            end
                        end,
                        -- "Jump and close".
                        ['o'] = function()
                            local menu = menu_utils.get_current()
                            if not menu then
                                return
                            end
                            local cursor = vim.api.nvim_win_get_cursor(menu.win)
                            local entry = menu.entries[cursor[1]]
                            local component =
                                entry:first_clickable(entry.padding.left + entry.components[1]:bytewidth())
                            if component then
                                menu:click_on(component, nil, 1, 'l')
                            end
                        end,
                        -- Close the dropbar entirely with <esc> and q.
                        ['q'] = close,
                        ['<esc>'] = close,
                    },
                },
                icons = {
                    kinds = {
                        symbols = vim.tbl_map(function(symbol)
                            return symbol .. ' '
                        end, symbol_kinds),
                    },
                },
            }
        end,
        config = function(_, opts)
            require('dropbar').setup(opts)

            vim.keymap.set('n', '<leader>w', require('dropbar.api').pick, { desc = 'Winbar pick' })
        end,
    },
}
