-- Jump my dear.
return {
    {
        'ggandor/leap.nvim',
        keys = {
            { 's', mode = { 'n', 'x', 'o' }, desc = 'Leap forward to' },
            { 'S', mode = { 'n', 'x', 'o' }, desc = 'Leap backward to' }
        },
        config = function(_, opts)
            local leap = require('leap')
            for k, v in pairs(opts) do
                leap.opts[k] = v
            end
            leap.add_default_mappings(true)
        end,
        init = function()
            vim.api.nvim_set_hl(0, 'LeapLabelPrimary', { bg = '#FBCAFF', fg = '#000000' })
        end
    }
}
