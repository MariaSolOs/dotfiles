-- Utilities for hiding/showing dotfiles.
local show_dotfiles = true
local filter_show = function()
    return true
end
local filter_hide = function(file)
    return not vim.startswith(file.name, '.')
end
local toggle_dotfiles = function()
    show_dotfiles = not show_dotfiles
    local new_filter = show_dotfiles and filter_show or filter_hide
    require('mini.files').refresh { content = { filter = new_filter } }
end

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
    require('helpers.keybindings').nmap(lhs, rhs, { buffer = buf_id, desc = desc })
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
            -- TODO: Sort like VS Code here.
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

            -- Show/hide dotfiles.
            vim.api.nvim_create_autocmd('User', {
                pattern = 'MiniFilesBufferCreate',
                callback = function(args)
                    local buf_id = args.data.buf_id
                    vim.keymap.set('n', 't.', toggle_dotfiles, { buffer = buf_id, desc = 'Toggle dotfiles' })
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
