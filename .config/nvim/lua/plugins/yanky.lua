-- Better copy/pasting.
return {
    'gbprod/yanky.nvim',
    opts = {
        ring = { history_length = 20 },
        highlight = { timer = 250 },
    },
    keys = {
        { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put yanked text after cursor' },
        { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' }, desc = 'Put yanked text before cursor' },
        { '=p', '<Plug>(YankyPutAfterLinewise)', desc = 'Put yanked text in line below' },
        { '=P', '<Plug>(YankyPutBeforeLinewise)', desc = 'Put yanked text in line above' },
        { '[y', '<Plug>(YankyCycleForward)', desc = 'Cycle forward through yank history' },
        { ']y', '<Plug>(YankyCycleBackward)', desc = 'Cycle backward through yank history' },
    },
}
