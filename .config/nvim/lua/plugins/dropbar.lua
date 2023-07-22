-- Winbar with breadcrumbs.
return {
    {
        'Bekaboo/dropbar.nvim',
        event = 'VeryLazy',
        config = function()
            local api = require 'dropbar.api'

            -- Closes all the windows in the current dropbar menu.
            local close = function()
                local menu = api.get_current_dropbar_menu()
                while menu and menu.prev_menu do
                    menu = menu.prev_menu
                end
                if menu then
                    menu:close()
                end
            end

            require('dropbar').setup {
                general = {
                    -- Disable the winbar in trouble.
                    enable = function(buf, win)
                        local buf_name = vim.api.nvim_buf_get_name(buf)
                        return not vim.api.nvim_win_get_config(win).zindex
                            and vim.bo[buf].buftype == ''
                            and buf_name ~= ''
                            and not buf_name:match 'Trouble$'
                            and not vim.wo[win].diff
                    end,
                },
                menu = {
                    win_configs = { border = 'rounded' },
                    keymaps = {
                        ['h'] = '<C-w>c',
                        ['l'] = function()
                            local menu = api.get_current_dropbar_menu()
                            if not menu then
                                return
                            end
                            local cursor = vim.api.nvim_win_get_cursor(menu.win)
                            local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
                            if component then
                                menu:click_on(component, nil, 1, 'l')
                            end
                        end,
                        ['q'] = close,
                        ['<esc>'] = close,
                    },
                },
            }

            vim.keymap.set('n', '<leader>w', api.pick, { desc = 'Winbar pick' })
        end,
    },
}
