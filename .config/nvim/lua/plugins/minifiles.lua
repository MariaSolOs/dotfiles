-- Utilities for creating splits.
local map_split = function(buf_id, lhs, direction)
    local minifiles = require 'mini.files'

    local rhs = function()
        local window = minifiles.get_target_window()

        -- Noop if the explorer isn't open or the cursor is on a directory.
        if window == nil or minifiles.get_fs_entry().fs_type == 'directory' then
            return
        end

        -- Make a new window and set it as target.
        local new_target_window
        vim.api.nvim_win_call(window, function()
            vim.cmd(direction .. ' split')
            new_target_window = vim.api.nvim_get_current_win()
        end)

        minifiles.set_target_window(new_target_window)
        -- Go in and close the explorer.
        minifiles.go_in()
        minifiles.close()
    end

    local desc = 'Split ' .. string.sub(direction, 12)
    vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
end

return {
    {
        'echasnovski/mini.files',
        keys = {
            {
                '<leader>f',
                -- Open the explorer in the current directory, with focus on the current
                -- file and in the last used state.
                function()
                    require('mini.files').open(vim.api.nvim_buf_get_name(0))
                end,
                desc = 'Open file explorer',
            },
        },
        opts = {
            mappings = {
                show_help = '?',
                go_in_plus = '<cr>',
                go_out_plus = '<tab>',
            },
            windows = {
                width_nofocus = 25,
            },
            content = {
                filter = function(entry)
                    return entry.fs_type ~= 'file' or entry.name ~= '.DS_Store'
                end,
                sort = function(entries)
                    -- idrk how this works, but it seems to sort stuff like VSCode
                    -- so I'm happy.
                    local function conv(s)
                        local res, dot = '', ''
                        for n, m, c in tostring(s):gmatch '(0*(%d*))(.?)' do
                            if n == '' then
                                dot, c = '', dot .. c
                            else
                                res = res .. (dot == '' and ('%03d%s'):format(#m, m) or '.' .. n)
                                dot, c = c:match '(%.?)(.*)'
                            end
                            res = res .. c:gsub('.', '\0%0')
                        end
                        return res
                    end

                    table.sort(entries, function(e1, e2)
                        -- Put directories first.
                        local e1_isdir, e2_isdir = e1.fs_type == 'directory', e2.fs_type == 'directory'
                        if e1_isdir and not e2_isdir then
                            return true
                        end
                        if not e1_isdir and e2_isdir then
                            return false
                        end

                        local p1, p2 = e1.path, e2.path
                        local ca, cb = conv(p1), conv(p2)
                        return ca < cb or ca == cb and p1 < p2
                    end)

                    return entries
                end,
            },
        },
        config = function(_, opts)
            require('mini.files').setup(opts)

            -- Add rounded corners.
            vim.api.nvim_create_autocmd('User', {
                pattern = 'MiniFilesWindowOpen',
                callback = function(args)
                    local win_id = args.data.win_id
                    vim.api.nvim_win_set_config(win_id, { border = 'rounded' })
                end,
            })

            -- Open files in splits.
            vim.api.nvim_create_autocmd('User', {
                pattern = 'MiniFilesBufferCreate',
                callback = function(args)
                    local buf_id = args.data.buf_id
                    map_split(buf_id, '<C-s>', 'belowright horizontal')
                    map_split(buf_id, '<C-v>', 'belowright vertical')
                end,
            })
        end,
    },
}
