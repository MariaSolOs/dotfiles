-- File explorer.
return {
    {
        'echasnovski/mini.files',
        version = false,
        keys = {
            {
                '<leader>f',
                function()
                    require('mini.files').open(vim.api.nvim_buf_get_name(0), false)
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
        },
        init = function()
            -- Add rounded corners.
            vim.api.nvim_create_autocmd('User', {
                pattern = 'MiniFilesWindowOpen',
                callback = function(args)
                    local win_id = args.data.win_id
                    vim.api.nvim_win_set_config(win_id, { border = 'rounded' })
                end,
            })
        end,
    },
}
