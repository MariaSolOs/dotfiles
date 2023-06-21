-- Highlight the current word under the cursor.
return {
    'RRethy/vim-illuminate',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
        delay = 200,
        large_file_cutoff = 2000,
        large_file_overrides = {
            providers = { 'lsp' },
        },
    },
    config = function(_, opts)
        require('illuminate').configure(opts)

        -- Remove these keymaps that illuminate creates and that I don't use.
        vim.keymap.del({ 'o', 'x' }, '<M-i>')
    end,
}
