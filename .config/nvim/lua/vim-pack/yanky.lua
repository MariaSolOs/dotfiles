local add = require('vim-pack').add

-- Better copy/pasting.
add {
    {
        src = 'gbprod/yanky.nvim',
        opts = {
            ring = { history_length = 20 },
            highlight = { timer = 250 },
        },
        on_setup = function()
            vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)', { desc = 'Put yanked text after cursor' })
            vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)', { desc = 'Put yanked text before cursor' })
            vim.keymap.set('n', '=p', '<Plug>(YankyPutAfterLinewise)', { desc = 'Put yanked text in line below' })
            vim.keymap.set('n', '=P', '<Plug>(YankyPutBeforeLinewise)', { desc = 'Put yanked text in line above' })
            vim.keymap.set('n', '[y', '<Plug>(YankyCycleForward)', { desc = 'Cycle forward through yank history' })
            vim.keymap.set('n', ']y', '<Plug>(YankyCycleBackward)', { desc = 'Cycle backward through yank history' })
            vim.keymap.set({ 'n', 'x' }, 'y', '<Plug>(YankyYank)', { desc = 'Yanky yank' })
        end,
    },
}
