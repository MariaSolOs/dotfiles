local add = require('vim-pack').add

-- Generate and open GitHub links.
add {
    {
        src = 'linrongbin16/gitlinker.nvim',
        opts = function()
            ---@param kind 'blob'|'blame'
            local function github_template(kind)
                return 'https://{_A.HOST}/{_A.ORG}/{_A.REPO}/'
                    .. kind
                    .. '/{_A.REV}/{_A.FILE}?plain=1#L{_A.LSTART}'
                    .. "{(_A.LEND > _A.LSTART and ('-L' .. _A.LEND) or '')}"
            end

            return {
                router = {
                    browse = {
                        ['^github%.palantir%.build'] = github_template('blob'),
                    },
                    blame = {
                        ['^github%.palantir%.build'] = github_template('blame'),
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
