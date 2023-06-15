-- Icon picker.
return {
    {
        'ziontee113/icon-picker.nvim',
        dependencies = 'stevearc/dressing.nvim',
        cmd = 'IconPickerNormal',
        opts = {
            disable_legacy_commands = true
        },
        keys = {
            { '<leader>ii', '<cmd>IconPickerNormal<cr>', desc = 'Pick and insert an icon' }
        }
    }
}
