local function close()
    local utils = require 'dropbar.utils'
    local menu = utils.menu.get_current()
    while menu and menu.prev_menu do
        menu = menu.prev_menu
    end
    if menu then
        menu:close()
    end
end

-- Breadcrumbs.
return {
    {
        'Bekaboo/dropbar.nvim',
        event = 'BufReadPre',
        keys = {
            {
                '<leader>w',
                function()
                    require('dropbar.api').pick()
                end,
                desc = 'Winbar pick',
            },
        },
        opts = function()
            -- Use my icons for a consistent UI but add a space postix.
            local symbol_icons = vim.deepcopy(require('icons').symbol_kinds, true)
            for icon_name, icon in pairs(symbol_icons) do
                symbol_icons[icon_name] = icon .. ' '
            end

            return {
                icons = {
                    kinds = { symbols = symbol_icons },
                    ui = {
                        -- Add a bit of more space.
                        bar = { separator = '  ' },
                    },
                },
                bar = {
                    update_events = {
                        -- Remove the 'WinEnter' event since I handle it manually for just showing the full
                        -- dropbar in the current window.
                        win = { 'CursorMoved', 'WinResized' },
                    },
                    sources = function()
                        local sources = require 'dropbar.sources'
                        local utils = require 'dropbar.utils'

                        -- Just show the path info for non-active windows.
                        return {
                            sources.path,
                            {
                                get_symbols = function(buf, win, cursor)
                                    if vim.api.nvim_get_current_win() ~= win then
                                        return {}
                                    end

                                    if vim.bo[buf].ft == 'markdown' then
                                        return sources.markdown.get_symbols(buf, win, cursor)
                                    end

                                    return utils.source
                                        .fallback({ sources.lsp, sources.treesitter })
                                        .get_symbols(buf, win, cursor)
                                end,
                            },
                        }
                    end,
                },
                menu = {
                    win_configs = { border = 'rounded' },
                    keymaps = {
                        -- Navigate back to the parent menu.
                        ['h'] = '<C-w>c',
                        -- Expands the entry if possible.
                        ['l'] = function()
                            local utils = require 'dropbar.utils'
                            local menu = utils.menu.get_current()
                            if not menu then
                                return
                            end
                            local cursor = vim.api.nvim_win_get_cursor(menu.win)
                            local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
                            if component then
                                menu:click_on(component, nil, 1, 'l')
                            end
                        end,
                        -- "Jump and close".
                        ['<cr>'] = function()
                            local utils = require 'dropbar.utils'
                            local menu = utils.menu.get_current()
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
            }
        end,
        config = function(_, opts)
            require('dropbar').setup(opts)

            vim.api.nvim_create_autocmd('WinEnter', {
                callback = function()
                    -- Refresh the dropbars except when entering the dropbar itself.
                    if vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].winbar == 1 then
                        require('dropbar.utils.bar').exec 'update'
                    end
                end,
            })
        end,
    },
}
