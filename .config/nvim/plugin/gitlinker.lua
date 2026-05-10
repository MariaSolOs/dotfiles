local add = require('vim-pack').add

-- Generate and open GitHub links.
add {
    {
        src = 'linrongbin16/gitlinker.nvim',
        opts = function()
            return {
                router = {
                    browse = {
                        ['^github%.palantir%.build'] = require('gitlinker.routers').github_browse,
                    },
                    blame = {
                        ['^github%.palantir%.build'] = require('gitlinker.routers').github_blame,
                    },
                },
            }
        end,
        on_setup = function()
            vim.keymap.set({ 'n', 'v' }, '<leader>gc', '<cmd>GitLink<cr>', { desc = 'Yank git link' })
            vim.keymap.set({ 'n', 'v' }, '<leader>go', '<cmd>GitLink! blame<cr>', { desc = 'Open git link' })
        end,
    },
}
