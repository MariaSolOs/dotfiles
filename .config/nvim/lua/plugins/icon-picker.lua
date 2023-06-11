-- Icon picker.
return {
    {
        'ziontee113/icon-picker.nvim',
        dependencies = 'stevearc/dressing.nvim',
        cmd = 'IconPickerInsert',
        opts = {
            disable_legacy_commands = true
        },
        init = function(_)
            vim.keymap.set({ 'n' }, '<leader>ii', '<cmd>IconPickerInsert<cr>', { desc = 'Pick and insert an icon' })
        end
    }
}
