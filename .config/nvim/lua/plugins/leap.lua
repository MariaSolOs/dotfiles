-- Jump my dear.
return {
    {
        'ggandor/leap.nvim',
        keys = {
            { 's', mode = { 'n', 'x', 'o' }, desc = 'Leap forward to' },
            { 'S', mode = { 'n', 'x', 'o' }, desc = 'Leap backward to' },
        },
        config = function()
            vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap-forward-to)', { desc = 'Leap forward to' })
            vim.keymap.set({ 'n', 'x', 'o' }, 'S', '<Plug>(leap-backward-to)', { desc = 'Leap backward to' })
        end,
        init = function()
            vim.api.nvim_set_hl(0, 'LeapLabelPrimary', { bg = '#FBCAFF', fg = '#000000' })
        end,
    },
}
