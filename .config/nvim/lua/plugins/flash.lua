-- Navigation with jump motions.
return {
    {
        'folke/flash.nvim',
        event = 'VeryLazy',
        opts = {
            jump = { nohlsearch = true },
            prompt = {
                win_config = {
                    border = 'none',
                    -- Place the prompt above the statusline.
                    row = -3,
                },
            },
            search = {
                exclude = {
                    'flash_prompt',
                    'qf',
                    function(win)
                        -- Floating windows from bqf.
                        if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match 'BqfPreview' then
                            return true
                        end

                        -- Non-focusable windows.
                        return not vim.api.nvim_win_get_config(win).focusable
                    end,
                },
            },
            modes = {
                -- Enable flash when searching with ? or /
                search = { enabled = true },
            },
        },
        keys = {
            {
                's',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').jump()
                end,
                desc = 'Flash',
            },
            {
                'r',
                mode = 'o',
                function()
                    require('flash').treesitter_search()
                end,
                desc = 'Treesitter Search',
            },
            {
                'R',
                mode = 'o',
                function()
                    require('flash').remote()
                end,
                desc = 'Remote Flash',
            },
        },
    },
}
