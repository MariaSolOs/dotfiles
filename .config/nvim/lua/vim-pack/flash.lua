local add_on_event = require('vim-pack').add_on_event

-- Navigation with jump motions.
add_on_event('UIEnter', {
    {
        src = 'folke/flash.nvim',
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
        on_setup = function()
            vim.keymap.set({ 'n', 'x', 'o' }, 's', function()
                require('flash').jump()
            end, { desc = 'Flash' })
            vim.keymap.set('o', 'r', function()
                require('flash').treesitter_search()
            end, { desc = 'Treesitter Search' })
            vim.keymap.set('o', 'R', function()
                require('flash').remote()
            end, { desc = 'Remote Flash' })
        end,
    },
})
