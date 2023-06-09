-- File tree.
return {
    {
        'nvim-tree/nvim-tree.lua',
        cmd = { 'NvimTreeToggle' },
        init = function()
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
            vim.keymap.set('n', '<leader>f', ':NvimTreeToggle<cr>', { desc = 'Toggle nvim tree' })
        end,
        opts = {
            sync_root_with_cwd = true,
            renderer = {
                icons = {
                    padding = '  '
                }
            }
        }
    }
}
