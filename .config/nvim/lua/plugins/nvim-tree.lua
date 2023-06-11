-- File tree.
return {
    {
        'nvim-tree/nvim-tree.lua',
        cmd = { 'NvimTreeToggle' },
        init = function()
            vim.keymap.set('n', '<leader>f', ':NvimTreeToggle<cr>', { desc = 'Toggle nvim tree' })
        end,
        opts = {
            hijack_cursor = true,
            sync_root_with_cwd = true,
            update_focused_file = {
                enable = true
            },
            view = {
                width = { min = 30, max = 50 }
            },
            renderer = {
                icons = {
                    padding = '  '
                },
                indent_markers = {
                    enable = true
                }
            },
            live_filter = {
                always_show_folders = false
            },
            actions = {
                open_file = {
                    quit_on_open = true
                }
            }
        }
    }
}
