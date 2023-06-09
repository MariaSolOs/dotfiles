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
                    require('mini.files').open(vim.api.nvim_buf_get_name(0), false)
                end,
                desc = 'File explorer',
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
                    local compare_alphanumerically = function(e1, e2)
                        -- Put directories first.
                        if e1.is_dir and not e2.is_dir then
                            return true
                        end
                        if not e1.is_dir and e2.is_dir then
                            return false
                        end
                        -- Order numerically based on digits if the text before them is equal.
                        if e1.pre_digits == e2.pre_digits and e1.digits ~= nil and e2.digits ~= nil then
                            return e1.digits < e2.digits
                        end
                        -- Otherwise order alphabetically ignoring case.
                        return e1.lower_name < e2.lower_name
                    end

                    local sorted = vim.tbl_map(function(entry)
                        local pre_digits, digits = entry.name:match '^(%D*)(%d+)'
                        if digits ~= nil then
                            digits = tonumber(digits)
                        end

                        return {
                            fs_type = entry.fs_type,
                            name = entry.name,
                            path = entry.path,
                            lower_name = entry.name:lower(),
                            is_dir = entry.fs_type == 'directory',
                            pre_digits = pre_digits,
                            digits = digits,
                        }
                    end, entries)
                    table.sort(sorted, compare_alphanumerically)
                    -- Keep only the necessary fields.
                    return vim.tbl_map(function(x)
                        return { name = x.name, fs_type = x.fs_type, path = x.path }
                    end, sorted)
                end,
            },
        },
        config = function(_, opts)
            local minifiles = require 'mini.files'
            minifiles.setup(opts)

            -- HACK: Make sure files always appear in the buffer list.
            local real_go_in = minifiles.go_in
            ---@diagnostic disable-next-line: duplicate-set-field
            function minifiles.go_in()
                real_go_in()
                local target = minifiles.get_target_window()
                local entry = minifiles.get_fs_entry()
                if entry ~= nil and entry.fs_type == 'file' and target ~= nil then
                    vim.bo[vim.api.nvim_win_get_buf(target)].buflisted = true
                end
            end

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

            -- Close the explorer when losing focus.
            vim.api.nvim_create_autocmd('BufEnter', {
                callback = vim.schedule_wrap(function()
                    local ft = vim.bo.filetype
                    if ft == 'minifiles' or ft == 'minifiles-help' then
                        return
                    end
                    local cur_win_id = vim.api.nvim_get_current_win()
                    require('mini.files').close()
                    pcall(vim.api.nvim_set_current_win, cur_win_id)
                end),
            })
        end,
    },
}
